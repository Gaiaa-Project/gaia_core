local RESOURCE_NAME <const> = Gaia.name

local Colors <const> = {
    success = '^2',
    info = '^5',
    warn = '^3',
    error = '^1',
    debug = '^4',
}

local Labels <const> = {
    success = 'SUCCESS',
    info = 'INFO',
    warn = 'WARN',
    error = 'ERROR',
    debug = 'DEBUG',
}

local RESET <const> = '^7'

--- Serialize a value into a string representation for printing.
---@param value any The value to serialize.
---@param indent? number The current indentation level (used recursively).
---@param seen? table A table to track already serialized tables (circular reference detection).
---@return string serialized The serialized string representation of the value.
local function formatValue(value, indent, seen)
    local t <const> = type(value)

    if value == nil then return 'nil' end
    if t == 'string' then return value end
    if t == 'number' or t == 'boolean' then return tostring(value) end
    if t == 'function' then return '[Function]' end
    if t == 'userdata' then return '[Userdata]' end
    if t == 'thread' then return '[Thread]' end
    if t == 'vector2' or t == 'vector3' or t == 'vector4' then return tostring(value) end

    if t == 'table' then
        indent = indent or 0
        seen = seen or {}

        if seen[value] then return '[Circular]' end
        seen[value] = true

        local keys <const> = {}
        for k in pairs(value) do
            keys[#keys + 1] = k
        end

        if #keys == 0 then return '{}' end

        local isArray <const> = #value > 0
        local parts <const> = {}
        local spacing <const> = string.rep('  ', indent + 1)
        local closingSpacing <const> = string.rep('  ', indent)

        if isArray then
            for i = 1, #value do
                parts[#parts + 1] = spacing .. formatValue(value[i], indent + 1, seen)
            end
        else
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)

            for i = 1, #keys do
                local k <const> = keys[i]
                local v <const> = formatValue(value[k], indent + 1, seen)
                parts[#parts + 1] = spacing .. tostring(k) .. ' = ' .. v
            end
        end

        seen[value] = nil

        return '{\n' .. table.concat(parts, ',\n') .. '\n' .. closingSpacing .. '}'
    end

    return tostring(value)
end

--- Format multiple arguments into a single space-separated string.
---@vararg any The values to format.
---@return string formatted The formatted string with all arguments serialized and joined.
local function formatArgs(...)
    local args <const> = { ... }
    local n <const> = select('#', ...)
    local parts <const> = {}

    for i = 1, n do
        parts[i] = formatValue(args[i])
    end

    return table.concat(parts, ' ')
end

--- Print a formatted log message to the console with color and level prefix.
---@param level string The log level (success, info, warn, error, debug).
---@vararg any The message(s) or variable(s) to print.
local function printMessage(level, ...)
    local color <const> = Colors[level]
    local label <const> = Labels[level]
    local content <const> = formatArgs(...)
    print(('%s[%s] %s:%s %s%s%s'):format(color, RESOURCE_NAME, label, RESET, color, content, RESET))
end

--- Print a success log message.
---@vararg any The message(s) or variable(s) to print.
function Gaia.print.success(...)
    printMessage('success', ...)
end

--- Print an info log message.
---@vararg any The message(s) or variable(s) to print.
function Gaia.print.info(...)
    printMessage('info', ...)
end

--- Print a warning log message.
---@vararg any The message(s) or variable(s) to print.
function Gaia.print.warn(...)
    printMessage('warn', ...)
end

--- Print an error log message and throw a Lua error with stack trace.
---@vararg any The message(s) or variable(s) to print.
function Gaia.print.error(...)
    printMessage('error', ...)
    error(formatArgs(...), 2)
end

--- Print a debug log message.
---@vararg any The message(s) or variable(s) to print.
function Gaia.print.debug(...)
    printMessage('debug', ...)
end
