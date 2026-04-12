--- Create a new Character object.
---@param sessionId number The player's server ID.
---@param data table The character row from the database { id, user_id, ped_model, x, y, z, heading, is_dead, playtime, last_played, created_at }.
---@return table character The character object instance.
function Gaia.CreateCharacter(sessionId, data)

    ---@class GaiaCharacter
    ---@field id number The database character ID.
    ---@field userId number The parent user ID.
    ---@field sessionId number The player's server ID.
    ---@field pedModel string The ped model name.
    ---@field isDead boolean Whether the character is dead.
    ---@field playtime number Total playtime in seconds (DB + session).
    ---@field lastPlayed string Timestamp of last play session.
    ---@field createdAt string Timestamp of character creation.
    local self = {}

    self.id = data.id
    self.userId = data.user_id
    self.sessionId = sessionId
    self.pedModel = data.ped_model or 'mp_m_freemode_01'
    self.isDead = data.is_dead or false
    self.lastPlayed = data.last_played
    self.createdAt = data.created_at

    local posX = data.x or 0
    local posY = data.y or 0
    local posZ = data.z or 70
    local posHeading = data.heading or 0
    local dbPlaytime = data.playtime or 0
    local sessionStart = os.time()

    --- Get the character position live from the ped entity.
    ---@param asVector? boolean Return as vector (true) or table (false/nil). Default: false.
    ---@param withHeading? boolean Include heading. If asVector and withHeading, returns vector4. Default: false.
    ---@return vector4|vector3|table position The current position.
    function self.getPosition(asVector, withHeading)
        local ped <const> = GetPlayerPed(tostring(self.sessionId))
        local coords <const> = GetEntityCoords(ped)
        local heading <const> = GetEntityHeading(ped)

        posX = coords.x
        posY = coords.y
        posZ = coords.z
        posHeading = heading

        if asVector then
            return withHeading and vector4(posX, posY, posZ, posHeading) or coords
        end

        local result = { x = posX, y = posY, z = posZ }
        if withHeading then
            result.heading = posHeading
        end
        return result
    end

    --- Set the character position (updates stored values and teleports the ped).
    ---@param x number The X coordinate.
    ---@param y number The Y coordinate.
    ---@param z number The Z coordinate.
    ---@param heading number The heading angle.
    function self.setPosition(x, y, z, heading)
        posX = x
        posY = y
        posZ = z
        posHeading = heading
        local ped <const> = GetPlayerPed(tostring(self.sessionId))
        SetEntityCoords(ped, x, y, z, false, false, false, false)
        SetEntityHeading(ped, heading)
    end

    --- Get the session playtime in seconds since the character was loaded.
    ---@return number sessionPlaytime The session playtime in seconds.
    function self.getSessionPlaytime()
        return os.time() - sessionStart
    end

    --- Get the total playtime (DB + current session).
    ---@return number playtime The total playtime in seconds.
    function self.getPlaytime()
        return dbPlaytime + self.getSessionPlaytime()
    end

    --- Flush the session playtime into the DB playtime and reset the session timer.
    function self.flushSessionPlaytime()
        dbPlaytime = dbPlaytime + self.getSessionPlaytime()
        sessionStart = os.time()
    end

    --- Update the last played timestamp to now.
    function self.updateLastPlayed()
        self.lastPlayed = os.date('%Y-%m-%d %H:%M:%S') --[[@as string]]
    end

    --- Check if the character has a specific permission (requires gaia_core RBAC).
    ---@param permission string The permission to check.
    ---@return boolean hasPermission Whether the character has the permission.
    function self.hasPermission(permission)
        return Gaia.permissions.hasPermission(self.id, permission)
    end

    --- Check if this character outranks another character (requires gaia_core RBAC).
    ---@param targetCharId number The target character ID.
    ---@return boolean canModify Whether this character outranks the target.
    function self.canModify(targetCharId)
        return Gaia.permissions.canModify(self.id, targetCharId)
    end

    --- Get the primary role of this character (requires gaia_core RBAC).
    ---@return table|nil role The primary role or nil.
    function self.getPrimaryRole()
        return Gaia.permissions.getPrimaryRole(self.id)
    end

    --- Get all roles of this character (requires gaia_core RBAC).
    ---@return table roles A list of roles.
    function self.getRoles()
        return Gaia.permissions.getCharacterRoles(self.id)
    end

    --- Get all resolved permissions of this character (requires gaia_core RBAC).
    ---@return table permissions A list of permission strings.
    function self.getPermissions()
        return Gaia.permissions.getCharacterPermissions(self.id)
    end

    --- Assign a role to this character (requires gaia_core RBAC).
    ---@param roleName string The role name.
    ---@param expiresIn? number Optional expiration in seconds.
    ---@param performedBy? number The character ID performing the action.
    ---@return boolean success Whether the role was assigned.
    function self.assignRole(roleName, expiresIn, performedBy)
        return Gaia.permissions.assignRole(self.id, roleName, expiresIn, performedBy)
    end

    --- Revoke a role from this character (requires gaia_core RBAC).
    ---@param roleName string The role name.
    ---@param performedBy? number The character ID performing the action.
    ---@return boolean success Whether the role was revoked.
    function self.revokeRole(roleName, performedBy)
        return Gaia.permissions.revokeRole(self.id, roleName, performedBy)
    end

    --- Serialize the character to a plain table.
    ---@return table data The serialized character data.
    function self.toJSON()
        return {
            id = self.id,
            userId = self.userId,
            pedModel = self.pedModel,
            x = posX,
            y = posY,
            z = posZ,
            heading = posHeading,
            isDead = self.isDead,
            playtime = self.getPlaytime(),
            sessionPlaytime = self.getSessionPlaytime(),
            lastPlayed = self.lastPlayed,
            createdAt = self.createdAt,
        }
    end

    return self
end
