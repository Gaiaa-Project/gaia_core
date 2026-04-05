--- Request and load an animation set into memory.
---@param animSet string The animation set name.
---@param timeout? number Maximum time in ms to wait (default: 10000).
---@return string animSet The loaded animation set name.
function Gaia.RequestAnimSet(animSet, timeout)
    return _GaiaInternal.StreamingRequest(
        function() RequestAnimSet(animSet) end,
        function() return HasAnimSetLoaded(animSet) end,
        'animSet', animSet, timeout
    ) --[[@as string]]
end
