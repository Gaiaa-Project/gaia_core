--- Apply vehicle properties from the server via StateBag sync.
--- The properties are automatically applied on the client that owns the entity.
---@param vehicle number The server-side vehicle entity handle.
---@param props VehicleProperties The vehicle properties to apply.
---@param fixVehicle? boolean Fix the vehicle after props have been set.
function Gaia.SetVehicleProperties(vehicle, props, fixVehicle)
    if not DoesEntityExist(vehicle) then
        Gaia.print.error(('Cannot set vehicle properties: entity %d does not exist'):format(vehicle))
    end

    Entity(vehicle).state:set('gaia_core:state:setVehicleProperties', {
        props = props,
        fixVehicle = fixVehicle or false,
    }, true)
end
