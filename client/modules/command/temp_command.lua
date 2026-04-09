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

Gaia.command.register('testrestart', function()
    SetTimeout(3000, function()
        TriggerServerEvent('gaia_chat:server:testRestart')
    end)
end, {
    description = 'Test passive chat with a fake restart message',
})

Gaia.command.register('testflood', function()
    TriggerServerEvent('gaia_chat:server:testFlood')
end, {
    description = 'Test passive chat with 15 messages over 15 seconds',
})
