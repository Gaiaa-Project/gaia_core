local EVENTS <const> = _GaiaInternal.CALLBACK_EVENTS
local TIMEOUT <const> = _GaiaInternal.CALLBACK_TIMEOUT

local pendingCallbacks = {}
local registeredCallbacks = {}

RegisterNetEvent(EVENTS.SERVER_RESPONSE, function(requestId, success, result)
    local pending <const> = pendingCallbacks[requestId]
    if not pending then return end

    pendingCallbacks[requestId] = nil

    if pending.timer then
        ClearTimeout(pending.timer)
    end

    if success then
        pending.p:resolve(result)
    else
        Gaia.print.error(('Callback response error: %s'):format(result))
        pending.p:reject(result)
    end
end)

RegisterNetEvent(EVENTS.CLIENT_REQUEST, function(requestId, eventName, ...)
    local handler <const> = registeredCallbacks[eventName]

    if not handler then
        TriggerServerEvent(EVENTS.CLIENT_RESPONSE, requestId, false, ('Callback \'%s\' not registered on client'):format(eventName))
        return
    end

    local ok <const>, result = pcall(handler, ...)

    if ok then
        TriggerServerEvent(EVENTS.CLIENT_RESPONSE, requestId, true, result)
    else
        TriggerServerEvent(EVENTS.CLIENT_RESPONSE, requestId, false, result)
    end
end)

--- Trigger a server callback and await the result (blocks the current thread).
---@param eventName string The name of the server callback to trigger.
---@vararg any Additional arguments to pass to the server callback.
---@return any result The result returned by the server callback.
function Gaia.TriggerServerCallback(eventName, ...)
    local requestId <const> = _GaiaInternal.GenerateUUID()
    local p <const> = promise.new()

    local timer <const> = SetTimeout(TIMEOUT, function()
        pendingCallbacks[requestId] = nil
        local msg <const> = ('Callback \'%s\' timed out after %dms'):format(eventName, TIMEOUT)
        Gaia.print.error(msg)
        p:reject(msg)
    end)

    pendingCallbacks[requestId] = {
        p = p,
        timer = timer,
    }

    TriggerServerEvent(EVENTS.SERVER_REQUEST, requestId, eventName, ...)

    return Citizen.Await(p)
end

--- Register a client-side callback handler.
---@param eventName string The name of the callback to register.
---@param handler function The handler function to execute when the callback is triggered.
function Gaia.RegisterClientCallback(eventName, handler)
    registeredCallbacks[eventName] = handler
end

--- Unregister a client-side callback handler.
---@param eventName string The name of the callback to unregister.
---@return boolean removed Whether the callback was successfully unregistered.
function Gaia.UnregisterClientCallback(eventName)
    if registeredCallbacks[eventName] then
        registeredCallbacks[eventName] = nil
        return true
    end
    return false
end

--- Check if a client-side callback handler is registered.
---@param eventName string The name of the callback to check.
---@return boolean registered Whether the callback is registered.
function Gaia.IsClientCallbackRegistered(eventName)
    return registeredCallbacks[eventName] ~= nil
end
