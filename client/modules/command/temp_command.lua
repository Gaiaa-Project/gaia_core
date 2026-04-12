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

Gaia.command.register('teststaff', function()
    local id <const> = tostring(GetGameTimer())

    SendNUIMessage({
        action = 'addStaffMessage',
        data = {
            id = id,
            type = 'system',
            icon = 'mdi-shield-check',
            content = 'Staff chat enabled — All messages will be sent to staff members only. Press ESC to exit.',
            timestamp = nil,
        },
    })

    SendNUIMessage({ action = 'setStaffMode', data = { enabled = true } })
    SendNUIMessage({ action = 'show', data = {} })
    SendNUIMessage({ action = 'focus', data = {} })
    SetNuiFocus(true, false)

    SetTimeout(1000, function()
        SendNUIMessage({
            action = 'addStaffMessage',
            data = {
                id = id .. '1',
                type = 'player',
                author = 'John Admin',
                content = 'Hey team, anyone online?',
                prefix = 'Administrator',
                prefixColor = '#f43f5e',
                timestamp = nil,
            },
        })
    end)

    SetTimeout(2500, function()
        SendNUIMessage({
            action = 'addStaffMessage',
            data = {
                id = id .. '2',
                type = 'player',
                author = 'Sarah Mod',
                content = 'Yes, just handled a report. All good now.',
                prefix = 'Moderator',
                prefixColor = '#f43f5e',
                timestamp = nil,
            },
        })
    end)

    SetTimeout(4000, function()
        SendNUIMessage({
            action = 'addStaffMessage',
            data = {
                id = id .. '3',
                type = 'player',
                author = '__self__',
                content = 'Nice, thanks for the update!',
                prefix = 'Owner',
                prefixColor = '#f43f5e',
                timestamp = nil,
            },
        })
    end)
end, {
    description = 'Test staff chat with fake messages',
})
