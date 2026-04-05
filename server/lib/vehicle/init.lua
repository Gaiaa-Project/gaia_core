local STATE_KEY <const> = 'gaia_core:state:initVehicle'

--- Initialize a vehicle from the server via StateBag sync.
--- Handles placing on ground, freezing position, and applying properties on the client.
---@param networkId number The network ID of the vehicle.
---@param options? InitVehicleOptions Initialization options { placeOnGround?, freezePosition?, props?, fixVehicle? }.
function Gaia.InitVehicle(networkId, options)
    local entity <const> = NetworkGetEntityFromNetworkId(networkId)

    if not entity or not DoesEntityExist(entity) then
        Gaia.print.error(('Cannot init vehicle: network ID %d does not resolve to an entity'):format(networkId))
    end

    Entity(entity).state:set(STATE_KEY, options or {}, true)
end
