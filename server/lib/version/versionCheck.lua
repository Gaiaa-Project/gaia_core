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

--- Compare two semver versions.
---@param current table { major, minor, patch }.
---@param latest table { major, minor, patch }.
---@return number result -1 if outdated, 0 if equal, 1 if ahead.
local function compareVersions(current, latest)
    for i = 1, 3 do
        if current[i] < latest[i] then return -1 end
        if current[i] > latest[i] then return 1 end
    end
    return 0
end

--- Check the latest GitHub release for a resource and log if an update is available.
---@param repository string The GitHub repository (e.g. 'Gaiaa-Project/gaia_core').
function Gaia.VersionCheck(repository)
    local resource <const> = GetInvokingResource() or GetCurrentResourceName()
    local rawVersion <const> = GetResourceMetadata(resource, 'version', 0)

    if not rawVersion then
        Gaia.print.warn(('Unable to determine version for \'%s\''):format(resource))
        return
    end

    local curMajor <const>, curMinor <const>, curPatch <const> = parseVersion(rawVersion)
    if not curMajor then
        Gaia.print.warn(('Invalid version format \'%s\' for \'%s\''):format(rawVersion, resource))
        return
    end

    local current <const> = { curMajor, curMinor, curPatch }

    SetTimeout(2000, function()
        PerformHttpRequest(
            ('https://api.github.com/repos/%s/releases/latest'):format(repository),
            function(status, response)
                if status ~= 200 then return end

                local data <const> = json.decode(response)
                if not data or data.prerelease then return end

                local latMajor <const>, latMinor <const>, latPatch <const> = parseVersion(data.tag_name)
                if not latMajor then return end

                local latest <const> = { latMajor, latMinor, latPatch }
                local cmp <const> = compareVersions(current, latest)

                if cmp == -1 then
                    Gaia.print.warn(('Update available for \'%s\': %s → %s\n%s'):format(resource, rawVersion, data.tag_name, data.html_url))
                elseif cmp == 0 then
                    Gaia.print.success(('\'%s\' is up to date (%s)'):format(resource, rawVersion))
                end
            end,
            'GET', '', { ['Accept'] = 'application/vnd.github.v3+json' }
        )
    end)
end
