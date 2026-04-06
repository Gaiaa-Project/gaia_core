local isServer <const> = Gaia.context == 'server'
local commands = {}
local cooldowns = {}

--- Build a cooldown key for tracking command usage.
---@param id number|string The identifier (source on server, command name on client).
---@param commandName string The command name.
---@return string key The cooldown key.
local function buildCooldownKey(id, commandName)
    return ('%s:%s'):format(tostring(id), commandName)
end

--- Check if a command is on cooldown.
---@param id number|string The identifier.
---@param commandName string The command name.
---@param cooldownMs number The cooldown duration in ms.
---@return boolean onCooldown Whether the command is on cooldown.
local function isOnCooldown(id, commandName, cooldownMs)
    if cooldownMs <= 0 then return false end

    local key <const> = buildCooldownKey(id, commandName)
    local lastUsed <const> = cooldowns[key]
    if not lastUsed then return false end

    return GetGameTimer() - lastUsed < cooldownMs
end

--- Set the cooldown timestamp for a command.
---@param id number|string The identifier.
---@param commandName string The command name.
local function setCooldown(id, commandName)
    cooldowns[buildCooldownKey(id, commandName)] = GetGameTimer()
end

if isServer then
    AddEventHandler('playerDropped', function()
        local prefix <const> = ('%d:'):format(source)
        for key in pairs(cooldowns) do
            if key:sub(1, #prefix) == prefix then
                cooldowns[key] = nil
            end
        end
    end)
end

--- Parse a raw argument string into the expected type.
---@param raw string|nil The raw argument value.
---@param def table The argument definition.
---@param allArgs table All raw arguments.
---@param currentIndex number The current argument index.
---@param playerSource number The player source (server) or local player ID (client).
---@return any value The parsed value.
---@return string|nil error The error message or nil.
local function parseArgValue(raw, def, allArgs, currentIndex, playerSource)
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
        if raw == 'me' then return playerSource, nil end
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
---@param suggestion table The command suggestion.
---@param playerSource number The player source.
---@return table|nil parsed The parsed arguments or nil on error.
---@return string|nil error The error message or nil.
local function validateArgs(rawArgs, suggestion, playerSource)
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

        local value, err = parseArgValue(raw, def, rawArgs, i, playerSource)

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

--- Register a command with argument parsing, optional permission checking (server), and cooldowns.
---
--- Server usage: `Gaia.command.register('kick', function(source, args, rawArgs) end, { permission = 'mod.kick', suggestion = { ... } })`
---
--- Client usage: `Gaia.command.register('marker', function(args, rawArgs) end, { suggestion = { ... } })`
---@param name string|table The command name or a list of aliases.
---@param callback function The command handler. Server: (source, parsedArgs, rawArgs). Client: (parsedArgs, rawArgs).
---@param options? table Command options { permission? (server only), allowConsole? (server only), suggestion?, cooldown? }.
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
    end

    local suggestion <const> = options and options.suggestion or nil
    local description <const> = options and options.description or nil

    local registered <const> = {
        name = name,
        callback = callback,
        description = description,
        suggestion = suggestion,
        cooldown = options and options.cooldown or 0,
    }

    if isServer then
        registered.permission = options and options.permission or nil
        registered.allowConsole = options and options.allowConsole or false
    end

    commands[name] = registered

    if isServer then
        TriggerClientEvent('gaia_chat:client:addCommand', -1, name, description)
    else
        TriggerEvent('gaia_chat:client:addCommand', name, description)
    end

    if suggestion and suggestion.arguments then
        local params <const> = {}
        for i = 1, #suggestion.arguments do
            local arg <const> = suggestion.arguments[i]
            params[i] = { name = arg.name, help = arg.help }
        end

        if isServer then
            TriggerClientEvent('gaia_chat:client:addSuggestion', -1, name, params)
        else
            TriggerEvent('gaia_chat:client:addSuggestion', name, params)
        end
    end

    if isServer then
        RegisterCommand(name, function(src, args)
            local cmd <const> = commands[name]
            if not cmd then return end

            if src == 0 and not cmd.allowConsole then
                Gaia.print.warn(('Command \'%s\' cannot be executed from console'):format(name))
                return
            end

            if cmd.permission and src ~= 0 then
                if not Gaia.permissions.hasPermission(src, cmd.permission) then
                    Gaia.print.warn(('Player %d attempted \'%s\' without permission \'%s\''):format(src, name, cmd.permission))
                    return
                end
            end

            if cmd.cooldown > 0 and src ~= 0 then
                if isOnCooldown(src, name, cmd.cooldown) then return end
                setCooldown(src, name)
            end

            local parsedArgs <const> = {}

            if cmd.suggestion and cmd.suggestion.arguments and #cmd.suggestion.arguments > 0 then
                local parsed, err = validateArgs(args, cmd.suggestion, src)

                if err then
                    if src == 0 then
                        Gaia.print.warn(('/%s: %s'):format(name, err))
                    else
                        TriggerClientEvent('gaia_core:client:commandError', src, name, err)
                    end
                    return
                end

                if parsed then
                    for k, v in pairs(parsed) do
                        parsedArgs[k] = v
                    end
                end
            end

            local ok <const>, result = pcall(cmd.callback, src, parsedArgs, args)
            if not ok then
                Gaia.print.warn(('Command \'%s\' threw an error: %s'):format(name, result))
            end
        end, true)
    else
        RegisterCommand(name, function(_, args)
            local cmd <const> = commands[name]
            if not cmd then return end

            if cmd.cooldown > 0 then
                if isOnCooldown(name, name, cmd.cooldown) then return end
                setCooldown(name, name)
            end

            local parsedArgs <const> = {}
            local playerSource <const> = GetPlayerServerId(PlayerId())

            if cmd.suggestion and cmd.suggestion.arguments and #cmd.suggestion.arguments > 0 then
                local parsed, err = validateArgs(args, cmd.suggestion, playerSource)

                if err then
                    Gaia.print.warn(('/%s: %s'):format(name, err))
                    return
                end

                if parsed then
                    for k, v in pairs(parsed) do
                        parsedArgs[k] = v
                    end
                end
            end

            local ok <const>, result = pcall(cmd.callback, parsedArgs, args)
            if not ok then
                Gaia.print.warn(('Command \'%s\' threw an error: %s'):format(name, result))
            end
        end, false)
    end
end

--- Unregister a command.
---@param name string The command name.
---@return boolean removed Whether the command was unregistered.
function Gaia.command.unregister(name)
    local cmd <const> = commands[name]
    if not cmd then return false end

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

--- Get all commands registered in the current context.
---@return table commands A list of registered commands.
local function getLocalCommands()
    local result <const> = {}
    for _, cmd in pairs(commands) do
        result[#result + 1] = cmd
    end
    return result
end

if isServer then
    --- Get all server-side registered commands.
    ---@return table commands A list of all server commands.
    function Gaia.command.getAllServer()
        return getLocalCommands()
    end

    Gaia.RegisterServerCallback('gaia_core:callback:getServerCommands', function()
        return getLocalCommands()
    end)
else
    --- Get all client-side registered commands.
    ---@return table commands A list of all client commands.
    function Gaia.command.getAllClient()
        return getLocalCommands()
    end

    --- Get all commands from both client and server.
    ---@return table commands A merged list of client and server commands.
    function Gaia.command.getAll()
        local client <const> = getLocalCommands()
        local server <const> = Gaia.TriggerServerCallback('gaia_core:callback:getServerCommands')

        local result <const> = {}
        local seen <const> = {}

        for i = 1, #client do
            result[#result + 1] = client[i]
            seen[client[i].name] = true
        end

        for i = 1, #server do
            if not seen[server[i].name] then
                result[#result + 1] = server[i]
            end
        end

        return result
    end
end
