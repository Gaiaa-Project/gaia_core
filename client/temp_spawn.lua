local function SetDefaultClothes(ped)
    for i = 0, 11 do
        SetPedComponentVariation(ped, i, 0, 0, 4)
    end

    for i = 0, 7 do
        ClearPedProp(ped, i)
    end
end

local function SpawnPlayer()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(100)
    end

    local pedModel = 'mp_m_freemode_01'
    Gaia.RequestModel(pedModel, 500)

    local playerPed = PlayerPedId()
    SetPlayerModel(PlayerId(), pedModel)
    playerPed = PlayerPedId()
    SetDefaultClothes(playerPed)

    local spawnPosition = vector3(0.0, 0.0, 70.0)
    local spawnHeading = 0.0

    SetEntityCoords(playerPed, spawnPosition.x, spawnPosition.y, spawnPosition.z, false, false, false, true)
    SetEntityHeading(playerPed, spawnHeading)
    SetEntityHealth(200)
    SetPedArmour(playerPed, 0.0)

    SetModelAsNoLongerNeeded(pedModel)

    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, false)
    SetPlayerControl(PlayerId(), true)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    DoScreenFadeIn(500)
end

CreateThread(function()
    while not NetworkIsPlayerActive(playerId()) do
        Wait(100)
    end

    SpawnPlayer()
end)