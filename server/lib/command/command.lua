Gaia.command = {}

local commands = {}
local cooldowns = {}

--- Build a cooldown key from source and command name.
---@param source number The player server ID.
---@param commandName string The command name.
---@return string key The cooldown key.
local function buildCooldownKey(source, commandName)
    return ('%d:%s'):format(source, commandName)
end

--- Check if a player is on cooldown for a command.
---@param source number The player server ID.
---@param commandName string The command name.
---@param cooldownMs number The cooldown duration in ms.
---@return boolean onCooldown Whether the player is on cooldown.
local function isOnCooldown(source, commandName, cooldownMs)
    if cooldownMs <= 0 then return false end

    local key <const> = buildCooldownKey(source, commandName)
    local lastUsed <const> = cooldowns[key]
    if not lastUsed then return false end

    return GetGameTimer() - lastUsed < cooldownMs
end

--- Set a cooldown for a player on a command.
---@param source number The player server ID.
---@param commandName string The command name.
local function setCooldown(source, commandName)
    cooldowns[buildCooldownKey(source, commandName)] = GetGameTimer()
end

AddEventHandler('playerDropped', function()
    local prefix <const> = ('%d:'):format(source)
    for key in pairs(cooldowns) do
        if key:sub(1, #prefix) == prefix then
            cooldowns[key] = nil
        end
    end
end)

--- Parse a raw argument string into the expected type.
---@param raw string|nil The raw argument value.
---@param def table The argument definition { name, type?, optional?, validator?, validatorError? }.
---@param allArgs table All raw arguments.
---@param currentIndex number The current argument index.
---@param source number The player server ID.
---@return any value The parsed value.
---@return string|nil error The error message or nil.
local function parseArgValue(raw, def, allArgs, currentIndex, source)
    if not raw or raw == '' then
        if def.optional then return nil, nil end
        return nil, ('Argument \'%s\' is required'):format(def.name)
    end

    local argType <const> = def.type or 'any'

    if argType == 'number' then
        local num <const> = tonumber(raw)
        if not num then return nil, ('\'%s\' must be a number'):format(def.name) end
        return num, nil

    elseif argType == 'player' then
        if raw == 'me' then return source, nil end
        local id <const> = tonumber(raw)
        if not id then return nil, ('\'%s\' must be a valid player ID'):format(def.name) end
        return id, nil

    elseif argType == 'coordinate' then
        local coord <const> = tonumber(raw)
        if not coord then return nil, ('\'%s\' must be a valid coordinate'):format(def.name) end
        return coord, nil

    elseif argType == 'boolean' then
        local lower <const> = raw:lower()
        if lower == 'true' or lower == '1' or lower == 'yes' then return true, nil end
        if lower == 'false' or lower == '0' or lower == 'no' then return false, nil end
        return nil, ('\'%s\' must be true/false'):format(def.name)

    elseif argType == 'merge' then
        local merged <const> = table.concat(allArgs, ' ', currentIndex)
        if merged == '' then return nil, ('\'%s\' is required'):format(def.name) end
        return merged, nil
    end

    return raw, nil
end

--- Validate and parse raw command arguments against argument definitions.
---@param rawArgs table The raw argument strings.
---@param suggestion table The command suggestion { arguments?, strictArgCount?, help? }.
---@param source number The player server ID.
---@return table|nil parsed The parsed arguments or nil on error.
---@return string|nil error The error message or nil.
local function validateArgs(rawArgs, suggestion, source)
    local defs <const> = suggestion.arguments
    if not defs or #defs == 0 then return {}, nil end

    local requiredCount = 0
    for i = 1, #defs do
        if not defs[i].optional then
            requiredCount = requiredCount + 1
        end
    end

    if suggestion.strictArgCount and #rawArgs ~= #defs then
        return nil, ('Expected %d arguments, got %d'):format(#defs, #rawArgs)
    end

    if #rawArgs < requiredCount then
        local missing <const> = defs[#rawArgs + 1]
        return nil, ('Missing required argument \'%s\''):format(missing and missing.name or '?')
    end

    local parsed <const> = {}

    for i = 1, #defs do
        local def <const> = defs[i]
        local raw <const> = rawArgs[i]

        local value, err = parseArgValue(raw, def, rawArgs, i, source)

        if err then return nil, err end

        parsed[def.name] = value

        if def.validator and value ~= nil then
            if not def.validator(value) then
                return nil, def.validatorError or ('Validation failed for \'%s\''):format(def.name)
            end
        end

        if def.type == 'merge' then break end
    end

    return parsed, nil
end

--- Send a chat suggestion for a command to all players.
---@param commandName string The command name.
---@param suggestion table The command suggestion.
local function sendSuggestion(commandName, suggestion)
    local args <const> = {}
    if suggestion.arguments then
        for i = 1, #suggestion.arguments do
            local arg <const> = suggestion.arguments[i]
            args[i] = {
                name = arg.name,
                help = arg.help or ('%s%s'):format(arg.type or 'any', arg.optional and ' (optional)' or ''),
            }
        end
    end

    TriggerClientEvent('chat:addSuggestion', -1, '/' .. commandName, suggestion.help or '', args)
end

--- Remove a chat suggestion for a command.
---@param commandName string The command name.
local function removeSuggestion(commandName)
    TriggerClientEvent('chat:removeSuggestion', -1, '/' .. commandName)
end

--- Register a server command with argument parsing, permission checking, and cooldowns.
---
--- Usage: `Gaia.command.register('kick', function(source, args, rawArgs) end, { permission = 'mod.kick', suggestion = { help = 'Kick a player', arguments = { { name = 'target', type = 'player' }, { name = 'reason', type = 'merge' } } } })`
---@param name string|table The command name or a list of aliases.
---@param callback function The command handler (source, parsedArgs, rawArgs).
---@param options? table Command options { permission?, allowConsole?, suggestion?, cooldown? }.
function Gaia.command.register(name, callback, options)
    if type(name) == 'table' then
        for i = 1, #name do
            Gaia.command.register(name[i], callback, options)
        end
        return
    end

    local existing <const> = commands[name]
    if existing then
        Gaia.print.warn(('Command \'%s\' already registered, overriding'):format(name))
        if existing.suggestion then removeSuggestion(name) end
    end

    local suggestion <const> = options and options.suggestion or nil

    local registered <const> = {
        name = name,
        permission = options and options.permission or nil,
        callback = callback,
        allowConsole = options and options.allowConsole or false,
        suggestion = suggestion,
        cooldown = options and options.cooldown or 0,
    }

    commands[name] = registered

    if suggestion then sendSuggestion(name, suggestion) end

    RegisterCommand(name, function(source, args)
        local cmd <const> = commands[name]
        if not cmd then return end

        if source == 0 and not cmd.allowConsole then
            Gaia.print.warn(('Command \'%s\' cannot be executed from console'):format(name))
            return
        end

        if cmd.permission and source ~= 0 then
            if not Gaia.permissions.hasPermission(source, cmd.permission) then
                Gaia.print.warn(('Player %d attempted \'%s\' without permission \'%s\''):format(source, name, cmd.permission))
                return
            end
        end

        if cmd.cooldown > 0 and source ~= 0 then
            if isOnCooldown(source, name, cmd.cooldown) then return end
            setCooldown(source, name)
        end

        local parsedArgs <const> = {}

        if cmd.suggestion and cmd.suggestion.arguments and #cmd.suggestion.arguments > 0 then
            local parsed, err = validateArgs(args, cmd.suggestion, source)

            if err then
                if source == 0 then
                    Gaia.print.warn(('/%s: %s'):format(name, err))
                else
                    TriggerClientEvent('gaia_core:client:commandError', source, name, err)
                end
                return
            end

            if parsed then
                for k, v in pairs(parsed) do
                    parsedArgs[k] = v
                end
            end
        end

        local ok <const>, result = pcall(cmd.callback, source, parsedArgs, args)
        if not ok then
            Gaia.print.warn(('Command \'%s\' threw an error: %s'):format(name, result))
        end
    end, true)
end

--- Unregister a command.
---@param name string The command name.
---@return boolean removed Whether the command was unregistered.
function Gaia.command.unregister(name)
    local cmd <const> = commands[name]
    if not cmd then return false end

    if cmd.suggestion then removeSuggestion(name) end
    commands[name] = nil
    return true
end

--- Check if a command is registered.
---@param name string The command name.
---@return boolean registered Whether the command is registered.
function Gaia.command.isRegistered(name)
    return commands[name] ~= nil
end

--- Get a registered command by name.
---@param name string The command name.
---@return table|nil command The registered command or nil.
function Gaia.command.get(name)
    return commands[name]
end

--- Get all registered commands.
---@return table commands A list of all registered commands.
function Gaia.command.getAll()
    local result <const> = {}
    for _, cmd in pairs(commands) do
        result[#result + 1] = cmd
    end
    return result
end
