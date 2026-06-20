--- Load characters from raw database rows into the cached user instance.
--- Creates GaiaCharacter objects and attaches them to the user.
---@param sessionId number The player's server ID.
---@param characters table The character rows from the database.
---@return number loaded The number of characters successfully loaded.
local function loadCharactersIntoCache(sessionId, characters)
    local user <const> = Gaia.cache.getPlayer(sessionId)

    if not user then
        Gaia.print.error(('Cannot load characters — no cached user for session %d'):format(sessionId))
        return 0
    end

    local loaded = 0

    for i = 1, #characters do
        local row <const> = characters[i]

        local character <const> = Gaia.CreateCharacter(sessionId, row)

        if not character then
            Gaia.print.error(('Failed to create character instance for id %d (session: %d)'):format(row.id, sessionId))
        else
            local added <const> = user.addCharacter(character)

            if not added then
                Gaia.print.error(('Failed to add character %d to user cache (session: %d) — may already exist'):format(row.id, sessionId))
            else
                loaded = loaded + 1
            end
        end
    end

    Gaia.print.success(('Loaded %d/%d characters into cache for %s (session: %d)'):format(loaded, #characters, user.identifiers.name, sessionId))

    return loaded
end

RegisterNetEvent('gaia_core:server:loadCharacters', function(sessionId, characters)
    if not sessionId then
        Gaia.print.error('Missing sessionId for character loading')
        return
    end

    if not characters or #characters == 0 then
        Gaia.print.info(('No characters to load for session %d'):format(sessionId))
        return
    end

    loadCharactersIntoCache(sessionId, characters)
end)
