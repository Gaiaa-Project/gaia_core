--- Parse a semver string into major, minor, patch numbers.
---@param version string The version string (e.g. '1.2.3').
---@return number|nil major The major version.
---@return number|nil minor The minor version.
---@return number|nil patch The patch version.
local function parseVersion(version)
    local major, minor, patch = version:match('(%d+)%.(%d+)%.(%d+)')
    if not major then return nil, nil, nil end
    return tonumber(major), tonumber(minor), tonumber(patch)
end

--- Check if a resource meets a minimum version requirement.
---@param resource string The resource name to check.
---@param minimumVersion string The minimum required version (semver format, e.g. '1.0.0').
---@return table result { ok, resource, requiredVersion, currentVersion, message }.
function Gaia.CheckDependency(resource, minimumVersion)
    local caller <const> = GetInvokingResource() or GetCurrentResourceName()
    local rawVersion <const> = GetResourceMetadata(resource, 'version', 0)

    if not rawVersion then
        local message <const> = ("'%s' requires '%s' but it is not started or has no version"):format(caller, resource)
        Gaia.print.warn(message)
        return {
            ok = false,
            resource = resource,
            requiredVersion = minimumVersion,
            currentVersion = 'unknown',
            message = message,
        }
    end

    local curMajor <const>, curMinor <const>, curPatch <const> = parseVersion(rawVersion)
    local minMajor <const>, minMinor <const>, minPatch <const> = parseVersion(minimumVersion)

    if not curMajor or not minMajor then
        local message <const> = ("Invalid version format: current='%s', required='%s'"):format(rawVersion, minimumVersion)
        Gaia.print.warn(message)
        return {
            ok = false,
            resource = resource,
            requiredVersion = minimumVersion,
            currentVersion = rawVersion,
            message = message,
        }
    end

    local current <const> = { curMajor, curMinor, curPatch }
    local minimum <const> = { minMajor, minMinor, minPatch }

    for i = 1, 3 do
        if current[i] < minimum[i] then
            local message <const> = ("'%s' requires '%s' >= %s (current: %s)"):format(caller, resource, minimumVersion, rawVersion)
            Gaia.print.warn(message)
            return {
                ok = false,
                resource = resource,
                requiredVersion = minimumVersion,
                currentVersion = rawVersion,
                message = message,
            }
        end
        if current[i] > minimum[i] then break end
    end

    return {
        ok = true,
        resource = resource,
        requiredVersion = minimumVersion,
        currentVersion = rawVersion,
        message = '',
    }
end
