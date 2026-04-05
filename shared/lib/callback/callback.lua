local CALLBACK_EVENTS <const> = {
    SERVER_REQUEST = '__gaia_cb_server_req',
    SERVER_RESPONSE = '__gaia_cb_server_res',
    CLIENT_REQUEST = '__gaia_cb_client_req',
    CLIENT_RESPONSE = '__gaia_cb_client_res',
}

local CALLBACK_TIMEOUT <const> = CallbackConfig.timeout

--- Generate a UUID v7 string based on timestamp and random hex segments.
---@return string uuid The generated UUID string.
local function generateUUID()
    local timestamp <const> = GetGameTimer()
    local hex <const> = string.format('%012x', timestamp)

    local function randomHex(length)
        local result <const> = {}
        for i = 1, length do
            result[i] = string.format('%x', math.random(0, 15))
        end
        return table.concat(result)
    end

    local variant <const> = string.format('%x', 8 + math.random(0, 3))

    return string.format(
        '%s-%s-7%s-%s%s-%s',
        hex:sub(1, 8),
        hex:sub(9, 12),
        randomHex(3),
        variant,
        randomHex(3),
        randomHex(12)
    )
end

_GaiaInternal.CALLBACK_EVENTS = CALLBACK_EVENTS
_GaiaInternal.CALLBACK_TIMEOUT = CALLBACK_TIMEOUT
_GaiaInternal.GenerateUUID = generateUUID
