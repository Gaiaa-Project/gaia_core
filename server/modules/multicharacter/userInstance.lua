--- Build a GaiaUser instance from user data and register it in the player cache.
--- Drops the player if any step fails.
---@param sessionId number The player's server ID.
---@param userData table The user data { id, license, discord_id }.
local function buildUserInstance(sessionId, userData)
    local user <const> = Gaia.CreateUser(sessionId, userData)

    if not user then
        Gaia.print.error(('Failed to create user instance for session %d'):format(sessionId))
        DropPlayer(tostring(sessionId), 'An error occurred while setting up your session. Please reconnect.')
        return
    end

    local cached <const> = Gaia.cache.addPlayer(sessionId, user)

    if not cached then
        Gaia.print.error(('Failed to cache user for session %d — player may already be cached'):format(sessionId))
        DropPlayer(tostring(sessionId), 'An error occurred while setting up your session. Please reconnect.')
        return
    end

    Gaia.print.success(('User instance created and cached for %s (session: %d, userId: %d)'):format(user.identifiers.name, sessionId, user.id))
end

RegisterNetEvent('gaia_core:server:createUserInstance', function(sessionId, userData)
    if not sessionId or not userData then
        Gaia.print.error('Missing sessionId or userData for user instance creation')
        return
    end

    if not userData.id or not userData.license or not userData.discord_id then
        Gaia.print.error(('Incomplete userData for session %d — requires id, license, discord_id'):format(sessionId))
        DropPlayer(tostring(sessionId), 'An error occurred while setting up your session. Please reconnect.')
        return
    end

    buildUserInstance(sessionId, userData)
end)
