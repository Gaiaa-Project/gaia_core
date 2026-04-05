--- Request and load a scaleform movie into memory.
---@param name string The scaleform movie name.
---@param timeout? number Maximum time in ms to wait (default: 10000).
---@return number handle The loaded scaleform movie handle.
function Gaia.RequestScaleformMovie(name, timeout)
    local handle <const> = RequestScaleformMovie(name)

    if HasScaleformMovieLoaded(handle) then return handle end

    local result <const> = Gaia.WaitFor(function()
        if HasScaleformMovieLoaded(handle) then return handle end
    end, ('Failed to load scaleformMovie \'%s\''):format(name), timeout or 10000)

    return result
end
