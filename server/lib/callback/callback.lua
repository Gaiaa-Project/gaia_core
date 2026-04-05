local EVENTS <const> = _GaiaInternal.CALLBACK_EVENTS
local TIMEOUT <const> = _GaiaInternal.CALLBACK_TIMEOUT
local RATE_LIMIT <const> = CallbackConfig.rateLimitMs

local pendingCallbacks = {}
local registeredCallbacks = {}
local lastCallTimestamps = {}

RegisterNetEvent(EVENTS.CLIENT_RESPONSE, function(requestId, success, result)
    local pending <const> = pendingCallbacks[requestId]
    if not pending then return end

    pendingCallbacks[requestId] = nil

    if pending.timer then
        ClearTimeout(pending.timer)
    end

    if success then
        pending.p:resolve(result)
    else
        pending.p:reject(result)
    end
end)

--- Check if a callback request from a player is rate limited.
---@param sessionId number The player server ID.
---@param eventName string The callback event name.
---@return boolean limited Whether the request is rate limited.
local function isRateLimited(sessionId, eventName)
    if RATE_LIMIT <= 0 then return false end

    local now <const> = GetGameTimer()
    local key <const> = ('%d:%s'):format(sessionId, eventName)
    local lastCall <const> = lastCallTimestamps[key]

    if lastCall and (now - lastCall) < RATE_LIMIT then
        return true
    end

    lastCallTimestamps[key] = now
    return false
end

RegisterNetEvent(EVENTS.SERVER_REQUEST, function(requestId, eventName, ...)
    local sessionId <const> = source

    if isRateLimited(sessionId, eventName) then
        Gaia.print.warn(('Callback \'%s\' rate limited for player %d'):format(eventName, sessionId))
        TriggerClientEvent(EVENTS.SERVER_RESPONSE, sessionId, requestId, false, ('Callback \'%s\' rate limited'):format(eventName))
        return
    end

    local handler <const> = registeredCallbacks[eventName]

    if not handler then
        TriggerClientEvent(EVENTS.SERVER_RESPONSE, sessionId, requestId, false, ('Callback \'%s\' not registered on server'):format(eventName))
        return
    end

    local ok <const>, result = pcall(handler, sessionId, ...)

    if ok then
        TriggerClientEvent(EVENTS.SERVER_RESPONSE, sessionId, requestId, true, result)
    else
        TriggerClientEvent(EVENTS.SERVER_RESPONSE, sessionId, requestId, false, result)
    end
end)

--- Clean up rate limit entries for a player when they disconnect.
---@param sessionId number The player server ID that disconnected.
local function cleanupPlayerRateLimit(sessionId)
    local prefix <const> = ('%d:'):format(sessionId)
    for key in pairs(lastCallTimestamps) do
        if key:sub(1, #prefix) == prefix then
            lastCallTimestamps[key] = nil
        end
    end
end

AddEventHandler('playerDropped', function()
    cleanupPlayerRateLimit(source)
end)

--- Trigger a client callback on a specific player and await the result (blocks the current thread).
---@param sessionId number The player server ID to trigger the callback on.
---@param eventName string The name of the client callback to trigger.
---@vararg any Additional arguments to pass to the client callback.
---@return any result The result returned by the client callback.
function Gaia.TriggerClientCallback(sessionId, eventName, ...)
    local requestId <const> = _GaiaInternal.GenerateUUID()
    local p <const> = promise.new()

    local timer <const> = SetTimeout(TIMEOUT, function()
        pendingCallbacks[requestId] = nil
        p:reject(('Callback \'%s\' for player %d timed out after %dms'):format(eventName, sessionId, TIMEOUT))
    end)

    pendingCallbacks[requestId] = {
        p = p,
        timer = timer,
    }

    TriggerClientEvent(EVENTS.CLIENT_REQUEST, sessionId, requestId, eventName, ...)

    return Citizen.Await(p)
end

--- Register a server-side callback handler.
---@param eventName string The name of the callback to register.
---@param handler function The handler function to execute when the callback is triggered (receives sessionId as first argument).
function Gaia.RegisterServerCallback(eventName, handler)
    registeredCallbacks[eventName] = handler
end

--- Unregister a server-side callback handler.
---@param eventName string The name of the callback to unregister.
---@return boolean removed Whether the callback was successfully unregistered.
function Gaia.UnregisterServerCallback(eventName)
    if registeredCallbacks[eventName] then
        registeredCallbacks[eventName] = nil
        return true
    end
    return false
end

--- Check if a server-side callback handler is registered.
---@param eventName string The name of the callback to check.
---@return boolean registered Whether the callback is registered.
function Gaia.IsServerCallbackRegistered(eventName)
    return registeredCallbacks[eventName] ~= nil
end
