local callers = {}
local controls = {}
local suppressed = {}
local tickActive = false

--- Resolve the caller name from an explicit argument, the invoking resource, or the current resource.
---@param caller? string An explicit caller name.
---@return string caller The resolved caller name.
local function resolveCaller(caller)
    if caller then return caller end
    local invoker <const> = GetInvokingResource()
    if invoker then return invoker end
    return GetCurrentResourceName()
end

--- Start the internal tick loop if not already running. Stops automatically when no controls remain.
local function ensureTick()
    if tickActive then return end
    tickActive = true

    Citizen.CreateThread(function()
        while next(controls) do
            for key in pairs(controls) do
                if not suppressed[key] then
                    DisableControlAction(0, key, true)
                end
            end
            Wait(0)
        end
        tickActive = false
    end)
end

--- Link a control key to a caller (bidirectional tracking).
---@param caller string The caller name.
---@param key number The control key to link.
local function linkControl(caller, key)
    if not callers[caller] then
        callers[caller] = {}
    end
    callers[caller][key] = true

    if not controls[key] then
        controls[key] = {}
    end
    controls[key][caller] = true
end

--- Unlink a control key from a caller (bidirectional cleanup).
---@param caller string The caller name.
---@param key number The control key to unlink.
local function unlinkControl(caller, key)
    if callers[caller] then
        callers[caller][key] = nil
        if not next(callers[caller]) then
            callers[caller] = nil
        end
    end

    if controls[key] then
        controls[key][caller] = nil
        if not next(controls[key]) then
            controls[key] = nil
            suppressed[key] = nil
        end
    end
end

--- Disable one or more control keys for the calling resource.
---@vararg number The control key(s) to disable.
function Gaia.AddDisabledControl(...)
    local caller <const> = resolveCaller()
    local args <const> = { ... }
    for i = 1, #args do
        linkControl(caller, args[i])
    end
    ensureTick()
end

--- Re-enable one or more previously disabled control keys for the calling resource.
---@vararg number The control key(s) to re-enable.
function Gaia.RemoveDisabledControl(...)
    local caller <const> = resolveCaller()
    local args <const> = { ... }
    for i = 1, #args do
        unlinkControl(caller, args[i])
    end
end

--- Clear all disabled controls for a specific caller or the calling resource.
---@param caller? string The caller name to clear. Defaults to the calling resource.
function Gaia.ClearDisabledControl(caller)
    local resolved <const> = resolveCaller(caller)
    local callerKeys <const> = callers[resolved]
    if not callerKeys then return end

    for key in pairs(callerKeys) do
        if controls[key] then
            controls[key][resolved] = nil
            if not next(controls[key]) then
                controls[key] = nil
                suppressed[key] = nil
            end
        end
    end

    callers[resolved] = nil
end

--- Clear all disabled controls from all callers.
function Gaia.ClearAllDisabledControls()
    callers = {}
    controls = {}
    suppressed = {}
end

--- Temporarily suppress one or more disabled controls (they stay registered but stop being disabled).
---@vararg number The control key(s) to suppress.
function Gaia.SuppressDisabledControl(...)
    local args <const> = { ... }
    for i = 1, #args do
        if controls[args[i]] then
            suppressed[args[i]] = true
        end
    end
end

--- Remove suppression on one or more disabled controls (they resume being disabled).
---@vararg number The control key(s) to unsuppress.
function Gaia.UnsuppressDisabledControl(...)
    local args <const> = { ... }
    for i = 1, #args do
        suppressed[args[i]] = nil
    end
end

--- Check if a control key is currently disabled.
---@param key number The control key to check.
---@return boolean disabled Whether the control is disabled.
function Gaia.HasDisabledControl(key)
    return controls[key] ~= nil
end

--- Check if a disabled control key is currently suppressed.
---@param key number The control key to check.
---@return boolean isSuppressed Whether the control is suppressed.
function Gaia.IsDisabledControlSuppressed(key)
    return suppressed[key] == true
end

--- Get all caller names that have disabled a specific control key.
---@param key number The control key to check.
---@return table callerList A list of caller names.
function Gaia.GetDisabledControlCallers(key)
    local result <const> = {}
    if controls[key] then
        for caller in pairs(controls[key]) do
            result[#result + 1] = caller
        end
    end
    return result
end

--- Get all currently disabled control keys.
---@return table keys A list of disabled control keys.
function Gaia.GetAllDisabledControls()
    local result <const> = {}
    for key in pairs(controls) do
        result[#result + 1] = key
    end
    return result
end
