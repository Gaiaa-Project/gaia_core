Gaia.cache = {}

local players = {}
local playerCount = 0
local licenseIndex = {}

--- Add a player to the cache.
---@param sessionId number The player's server ID.
---@param user table The GaiaUser object.
---@return boolean success Whether the player was added.
function Gaia.cache.addPlayer(sessionId, user)
    if not sessionId or not user then return false end
    if players[sessionId] then return false end

    players[sessionId] = user
    playerCount = playerCount + 1

    if user.license then
        licenseIndex[user.license] = sessionId
    end

    return true
end

--- Remove a player from the cache.
---@param sessionId number The player's server ID.
---@return boolean success Whether the player was removed.
function Gaia.cache.removePlayer(sessionId)
    local user <const> = players[sessionId]
    if not user then return false end

    if user.license and licenseIndex[user.license] then
        licenseIndex[user.license] = nil
    end

    players[sessionId] = nil
    playerCount = playerCount - 1

    return true
end

--- Get a player from the cache by session ID.
---@param sessionId number The player's server ID.
---@return table|nil user The GaiaUser object or nil.
function Gaia.cache.getPlayer(sessionId)
    return players[sessionId]
end

--- Get a player from the cache by license.
---@param license string The player's Rockstar license.
---@return table|nil user The GaiaUser object or nil.
function Gaia.cache.getPlayerByLicense(license)
    local sessionId <const> = licenseIndex[license]
    if not sessionId then return nil end
    return players[sessionId]
end

--- Get the current character of a cached player.
---@param sessionId number The player's server ID.
---@return table|nil character The current GaiaCharacter or nil.
function Gaia.cache.getCurrentCharacter(sessionId)
    local user <const> = players[sessionId]
    if not user then return nil end
    return user.currentCharacter
end

--- Check if a player exists in the cache.
---@param sessionId number The player's server ID.
---@return boolean exists Whether the player is cached.
function Gaia.cache.hasPlayer(sessionId)
    return players[sessionId] ~= nil
end

--- Check if a license is in the cache.
---@param license string The player's Rockstar license.
---@return boolean exists Whether the license is cached.
function Gaia.cache.hasLicense(license)
    return licenseIndex[license] ~= nil
end

--- Get all cached players.
---@return table players All players indexed by session ID.
function Gaia.cache.getAllPlayers()
    return players
end

--- Get the number of cached players.
---@return number count The player count.
function Gaia.cache.getPlayerCount()
    return playerCount
end

--- Get all session IDs of cached players.
---@return table sessionIds A list of session IDs.
function Gaia.cache.getAllSessionIds()
    local result <const> = {}
    for sessionId in pairs(players) do
        result[#result + 1] = sessionId
    end
    return result
end

--- Iterate over all cached players with a callback.
---@param cb function The callback (sessionId, user). Return false to stop iteration.
function Gaia.cache.forEach(cb)
    for sessionId, user in pairs(players) do
        if cb(sessionId, user) == false then return end
    end
end

--- Find a player matching a condition.
---@param cb function The predicate (sessionId, user). Return true to match.
---@return table|nil user The first matching user or nil.
---@return number|nil sessionId The session ID of the match or nil.
function Gaia.cache.findPlayer(cb)
    for sessionId, user in pairs(players) do
        if cb(sessionId, user) then return user, sessionId end
    end
    return nil, nil
end

--- Clear the entire cache.
function Gaia.cache.clear()
    players = {}
    licenseIndex = {}
    playerCount = 0
end
