if not _VERSION:find('5.4') then
    error('Lua 5.4 must be enabled in the resource manifest!', 2)
end

local gaia_core <const> = 'gaia_core'
local resourceName <const> = GetCurrentResourceName()

if resourceName == gaia_core then return end

if Gaia and Gaia.name == gaia_core then
    error(("Cannot load gaia_core more than once.\n\tRemove any duplicate entries from '@%s/fxmanifest.lua'"):format(resourceName))
end

if GetResourceState(gaia_core) ~= 'started' then
    error('^1gaia_core must be started before this resource.^0', 0)
end

Gaia = exports[gaia_core]:exportedObject()