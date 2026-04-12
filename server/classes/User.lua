--- Create a new User object.
---@param sessionId number The player's server ID.
---@param data table The user row from the database { id, license, discord_id, ip, last_played_character, total_playtime, last_seen, created_at }.
---@return table user The user object instance.
function Gaia.CreateUser(sessionId, data)

    ---@class GaiaUser
    ---@field id number The database user ID.
    ---@field sessionId number The player's server ID.
    ---@field license string The player's Rockstar license.
    ---@field discordId string The player's Discord ID.
    ---@field identifiers table All player identifiers.
    ---@field characters table Characters indexed by ID.
    ---@field currentCharacter table|nil The currently active character.
    ---@field isOnline boolean Whether the user is currently online.
    ---@field lastSeen number Timestamp of last activity.
    ---@field lastPlayedCharacter number|nil The ID of the last played character.
    ---@field totalPlaytime number Total playtime across all characters in seconds.
    ---@field createdAt string Timestamp of when the user was created.
    local self = {}

    self.id = data.id
    self.sessionId = sessionId
    self.license = data.license
    self.discordId = data.discord_id
    self.identifiers = Gaia.GetIdentifiers(sessionId)
    self.characters = {}
    self.currentCharacter = nil
    self.isOnline = true
    self.lastSeen = os.time()
    self.lastPlayedCharacter = data.last_played_character or nil
    self.totalPlaytime = data.total_playtime or 0
    self.createdAt = data.created_at

    --- Get a specific identifier by type.
    ---@param identifierType string The type of identifier (license, steam, discord, etc.).
    ---@return string|nil identifier The identifier value or nil.
    function self.getIdentifier(identifierType)
        return self.identifiers[identifierType]
    end

    --- Get a specific character by ID.
    ---@param charId number The character ID.
    ---@return table|nil character The character or nil.
    function self.getCharacter(charId)
        return self.characters[charId]
    end

    --- Check if the user has a specific character.
    ---@param charId number The character ID.
    ---@return boolean exists Whether the character exists.
    function self.hasCharacter(charId)
        return self.characters[charId] ~= nil
    end

    --- Get the number of characters.
    ---@return number count The character count.
    function self.getCharacterCount()
        local count = 0
        for _ in pairs(self.characters) do
            count = count + 1
        end
        return count
    end

    --- Add a character to the user.
    ---@param character table The character object.
    ---@return boolean success Whether the character was added.
    function self.addCharacter(character)
        if not character or not character.id then return false end
        if self.characters[character.id] then return false end
        self.characters[character.id] = character
        return true
    end

    --- Remove a character from the user.
    ---@param charId number The character ID to remove.
    ---@return boolean success Whether the character was removed.
    function self.removeCharacter(charId)
        if not self.characters[charId] then return false end
        if self.currentCharacter and self.currentCharacter.id == charId then
            self.currentCharacter = nil
        end
        self.characters[charId] = nil
        return true
    end

    --- Set the active character.
    ---@param charId number The character ID to set as active.
    ---@return boolean success Whether the character was found and set.
    function self.setCurrentCharacter(charId)
        local character <const> = self.characters[charId]
        if not character then return false end
        self.currentCharacter = character
        self.lastPlayedCharacter = charId
        return true
    end

    --- Clear the active character.
    function self.clearCurrentCharacter()
        self.currentCharacter = nil
    end

    --- Trigger a client event on this user's client.
    ---@param eventName string The event name.
    ---@vararg any Additional arguments to pass to the event.
    function self.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, self.sessionId, ...)
    end

    --- Set the online status.
    ---@param status boolean The online status.
    function self.setOnline(status)
        self.isOnline = status
        if not status then
            self.lastSeen = os.time()
        end
    end

    --- Update the last seen timestamp to now.
    function self.updateLastSeen()
        self.lastSeen = os.time()
    end

    --- Recalculate total playtime from all characters.
    function self.updateTotalPlaytime()
        local total = 0
        for _, character in pairs(self.characters) do
            if character.playtime then
                total = total + character.playtime
            end
        end
        self.totalPlaytime = total
    end

    --- Disconnect the user from the server.
    ---@param reason? string The disconnect reason.
    function self.drop(reason)
        if not self.isOnline then return end
        DropPlayer(tostring(self.sessionId), reason or 'Disconnected by server')
        self.isOnline = false
        self.lastSeen = os.time()
    end

    --- Serialize the user to a plain table.
    ---@return table data The serialized user data.
    function self.toJSON()
        return {
            id = self.id,
            sessionId = self.sessionId,
            license = self.license,
            discordId = self.discordId,
            isOnline = self.isOnline,
            lastSeen = self.lastSeen,
            lastPlayedCharacter = self.lastPlayedCharacter,
            totalPlaytime = self.totalPlaytime,
            characterCount = self.getCharacterCount(),
            currentCharacterId = self.currentCharacter and self.currentCharacter.id or nil,
            createdAt = self.createdAt,
        }
    end

    return self
end
