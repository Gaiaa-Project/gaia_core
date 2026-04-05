--- Request and load a model into memory.
---@param model string|number The model name or hash.
---@param timeout? number Maximum time in ms to wait (default: 10000).
---@return number hash The loaded model hash.
function Gaia.RequestModel(model, timeout)
    local hash <const> = type(model) == 'string' and GetHashKey(model) or model

    if not IsModelValid(hash) and not IsModelInCdimage(hash) then
        Gaia.print.error(('Invalid model \'%s\''):format(model))
    end

    return _GaiaInternal.StreamingRequest(
        function() RequestModel(hash) end,
        function() return HasModelLoaded(hash) end,
        'model', hash, timeout
    ) --[[@as number]]
end
