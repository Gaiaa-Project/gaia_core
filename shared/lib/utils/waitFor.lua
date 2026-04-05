--- Wait until a condition is met or timeout is reached.
--- The condition function is called every frame until it returns a non-nil value.
---@param cb function A function that returns a value when the condition is met, or nil to keep waiting.
---@param errMessage? string Custom error message on timeout.
---@param timeout? number|false Maximum time in ms to wait (default: 1000). Pass false to wait indefinitely.
---@return any result The first non-nil value returned by the condition function.
function Gaia.WaitFor(cb, errMessage, timeout)
    local value = cb()
    if value ~= nil then return value end

    local ms <const> = timeout == false and false or (type(timeout) == 'number' and timeout or 1000)
    local start <const> = ms and GetGameTimer()

    while value == nil do
        Wait(0)

        if ms then
            local elapsed <const> = GetGameTimer() - start
            if elapsed > ms then
                Gaia.print.error(('%s (waited %dms)'):format(errMessage or 'Gaia.WaitFor timed out', elapsed))
            end
        end

        value = cb()
    end

    return value
end
