local DEFAULT_TIMEOUT <const> = 10000

--- Request a streaming asset and wait until it is loaded or timeout.
---@param request function The function that initiates the asset loading.
---@param hasLoaded function The function that checks if the asset is loaded.
---@param assetType string The type of asset for error messages.
---@param asset string|number The asset identifier.
---@param timeout? number Maximum time in ms to wait (default: 10000).
---@return string|number asset The loaded asset identifier.
function _GaiaInternal.StreamingRequest(request, hasLoaded, assetType, asset, timeout)
    if hasLoaded() then return asset end

    request()

    local result <const> = Gaia.WaitFor(function()
        if hasLoaded() then return asset end
    end, ('Failed to load %s \'%s\''):format(assetType, asset), timeout or DEFAULT_TIMEOUT)

    return result
end
