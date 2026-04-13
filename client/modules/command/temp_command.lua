Gaia.command.register('car', function(args)
    local model <const> = args.model or 'adder'
    local hash <const> = GetHashKey(model)
    Gaia.RequestModel(hash)
    local playerPed <const> = PlayerPedId()
    local coords <const> = GetEntityCoords(playerPed, false)
    local heading <const> = GetEntityHeading(playerPed)
    local vehicle <const> = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
end, {
    description = 'Spawn a vehicle',
    suggestion = {
        arguments = {
            { name = 'model', type = 'string', optional = true, help = 'Vehicle model name' },
        },
    },
})
