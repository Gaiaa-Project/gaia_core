--- Check if a required permission is granted by a set of permissions (supports wildcards and negation).
---@param granted table A set of granted permissions { ['perm.name'] = true }.
---@param required string The permission to check.
---@return boolean allowed Whether the permission is granted.
function _GaiaInternal.MatchPermission(granted, required)
    if granted['-' .. required] then return false end

    if granted[required] then return true end

    if granted['*'] then
        return not granted['-' .. required]
    end

    local dotIndex <const> = required:find('%.')
    if not dotIndex then return false end

    local namespace <const> = required:sub(1, dotIndex - 1)
    local action <const> = required:sub(dotIndex + 1)

    if granted[namespace .. '.*'] then return true end
    if granted['*.' .. action] then return true end

    return false
end

--- Validate that a permission string has a valid format.
---@param permission string The permission string to validate.
---@return boolean valid Whether the permission is valid.
function _GaiaInternal.IsValidPermission(permission)
    if permission == '*' then return true end

    local clean <const> = permission:sub(1, 1) == '-' and permission:sub(2) or permission

    return clean:match('^[a-zA-Z_]+%.[a-zA-Z_*%.]+$') ~= nil
end
