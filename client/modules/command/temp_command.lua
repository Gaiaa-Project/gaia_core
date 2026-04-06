Gaia.command.register('car', function(args)
    local hash <const> = GetHashKey('adder')
    Gaia.RequestModel(hash)
    local vehicle <const> = CreateVehicle(hash, 0.0, 0.0, 70.0, 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
end, {
    suggestion = {
        help = 'Spawn a vehicle',
        arguments = {
            { name = 'model', type = 'string', optional = true, help = 'Vehicle model name' },
        },
    },
})
