-- QBCore Initialization
local QBCore = exports['qb-core']:GetCoreObject()

-- === afk.lua ===
local isLoggedIn = LocalPlayer.state.isLoggedIn
local checkUser = true
local prevPos, time = nil, nil
local timeMinutes = {
    ['900'] = 'minutes',
    ['600'] = 'minutes',
    ['300'] = 'minutes',
    ['150'] = 'minutes',
    ['60'] = 'minutes',
    ['30'] = 'seconds',
    ['20'] = 'seconds',
    ['10'] = 'seconds',
}

local function updatePermissionLevel()
    QBCore.Functions.TriggerCallback('qb-afkkick:server:GetPermissions', function(userGroups)
        for k in pairs(userGroups) do
            if Config.ignoredGroups[k] then
                checkUser = false
                break
            end
            checkUser = true
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    updatePermissionLevel()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnPermissionUpdate', function()
    updatePermissionLevel()
end)

CreateThread(function()
    while true do
        Wait(10000)
        local ped = PlayerPedId()
        if isLoggedIn == true or Config.kickInCharMenu == true then
            if checkUser then
                local currPos = GetEntityCoords(ped, true)
                if prevPos then
                    if currPos == prevPos then
                        if time then
                            if time > 0 then
                                local _type = timeMinutes[tostring(time)]
                                if _type == 'minutes' then
                                    QBCore.Functions.Notify(Lang:t('afk.will_kick') .. math.ceil(time / 60) .. Lang:t('afk.time_minutes'), 'error', 10000)
                                elseif _type == 'seconds' then
                                    QBCore.Functions.Notify(Lang:t('afk.will_kick') .. time .. Lang:t('afk.time_seconds'), 'error', 10000)
                                end
                                time -= 10
                            else
                                TriggerServerEvent('KickForAFK')
                            end
                        else
                            time = Config.secondsUntilKick
                        end
                    else
                        time = Config.secondsUntilKick
                    end
                end
                prevPos = currPos
            end
        end
    end
end)

-- === binoculars.lua ===
local binoculars = false
local fov_max = 70.0
local fov_min = 5.0 -- max zoom level (smaller fov is more zoom)
local fov = (fov_max + fov_min) * 0.5
local speed_lr = 8.0 -- speed by which the camera pans left-right
local speed_ud = 8.0 -- speed by which the camera pans up-down

--FUNCTIONS--

local function HideHUDThisFrame()
    local componentsToHide = {1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 15, 18, 19}

    for i = 1, #componentsToHide do
        local component = componentsToHide[i]
        HideHudComponentThisFrame(component)
    end

    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
end

local function checkInputRot(cam, zoomValue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rot = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rot.z + rightAxisX * -1.0 * speed_ud * (zoomValue + 0.1)
        local new_x = math.max(math.min(20.0, rot.x + rightAxisY * -1.0 * speed_lr * (zoomValue + 0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        SetEntityHeading(PlayerPedId(), new_z)
    end
end

local function handleZoom(cam)
    local ped = PlayerPedId()
    local scrollUpControl = IsPedSittingInAnyVehicle(ped) and 17 or 241
    local scrollDownControl = IsPedSittingInAnyVehicle(ped) and 16 or 242

    if IsControlJustPressed(0, scrollUpControl) then
        fov = math.max(fov - Config.Binoculars.zoomSpeed, fov_min)
    end

    if IsControlJustPressed(0, scrollDownControl) then
        fov = math.min(fov + Config.Binoculars.zoomSpeed, fov_max)
    end

    local current_fov = GetCamFov(cam)

    if math.abs(fov - current_fov) < 0.1 then
        fov = current_fov
    end

    SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
end

--THREADS--

function binocularLoop()
    CreateThread(function()
        local ped = PlayerPedId()

        if not IsPedSittingInAnyVehicle(ped) then
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_BINOCULARS', 0, true)
            PlayPedAmbientSpeechNative(ped, 'GENERIC_CURSE_MED', 'SPEECH_PARAMS_FORCE')
        end

        Wait(2500)

        SetTimecycleModifier('default')
        SetTimecycleModifierStrength(0.3)
        local scaleform = RequestScaleformMovie('BINOCULARS')
        while not HasScaleformMovieLoaded(scaleform) do
            Wait(10)
        end

        local cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
        AttachCamToEntity(cam, ped, 0.0, 0.0, 1.0, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(ped), 2)
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, true, false)
        PushScaleformMovieFunction(scaleform, 'SET_CAM_LOGO')
        PushScaleformMovieFunctionParameterInt(0) -- 0 for nothing, 1 for LSPD logo
        PopScaleformMovieFunctionVoid()

        while binoculars and IsPedUsingScenario(ped, 'WORLD_HUMAN_BINOCULARS') do
            if IsControlJustPressed(0, Config.Binoculars.storeBinocularsKey) then
                binoculars = false
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                ClearPedTasks(ped)
            end

            local zoomValue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
            checkInputRot(cam, zoomValue)
            handleZoom(cam)
            HideHUDThisFrame()
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
            Wait(0)
        end
        binoculars = false
        ClearTimecycleModifier()
        fov = (fov_max + fov_min) * 0.5
        RenderScriptCams(false, false, 0, true, false)
        SetScaleformMovieAsNoLongerNeeded(scaleform)
        DestroyCam(cam, false)
        SetNightvision(false)
        SetSeethrough(false)
    end)
end

--EVENTS--

-- Activate binoculars
RegisterNetEvent('binoculars:Toggle', function()
    binoculars = not binoculars
    if binoculars then binocularLoop() return end
    ClearPedTasks(PlayerPedId())
end)


-- === calmai.lua ===
--  Relationship Types:
--  0 = Companion
--  1 = Respect
--  2 = Like
--  3 = Neutral
--  4 = Dislike
--  5 = Hate

SetRelationshipBetweenGroups(1, `AMBIENT_GANG_HILLBILLY`, `PLAYER`)
SetRelationshipBetweenGroups(1, `AMBIENT_GANG_BALLAS`, `PLAYER`)
SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MEXICAN`, `PLAYER`)
SetRelationshipBetweenGroups(1, `AMBIENT_GANG_FAMILY`, `PLAYER`)
SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MARABUNTE`, `PLAYER`)
SetRelationshipBetweenGroups(1, `AMBIENT_GANG_SALVA`, `PLAYER`)
SetRelationshipBetweenGroups(1, `AMBIENT_GANG_LOST`, `PLAYER`)
SetRelationshipBetweenGroups(1, `GANG_1`, `PLAYER`)
SetRelationshipBetweenGroups(1, `GANG_2`, `PLAYER`)
SetRelationshipBetweenGroups(1, `GANG_9`, `PLAYER`)
SetRelationshipBetweenGroups(1, `GANG_10`, `PLAYER`)
SetRelationshipBetweenGroups(1, `FIREMAN`, `PLAYER`)
SetRelationshipBetweenGroups(1, `MEDIC`, `PLAYER`)
SetRelationshipBetweenGroups(1, `COP`, `PLAYER`)
SetRelationshipBetweenGroups(1, `PRISONER`, `PLAYER`)


-- === carwash.lua ===
local washingVeh, listen = false, false
local washPoly = {}

local function washLoop()
    CreateThread(function()
        while listen do
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local driver = GetPedInVehicleSeat(veh, -1)
            local dirtLevel = GetVehicleDirtLevel(veh)
            if driver == ped and not washingVeh then
                if IsControlPressed(0, 38) then
                    if dirtLevel > Config.CarWash.dirtLevel then
                        TriggerServerEvent('qb-carwash:server:washCar')
                    else
                        QBCore.Functions.Notify(Lang:t('wash.dirty'), 'error')
                    end
                    listen = false
                    break
                end
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent('qb-carwash:client:washCar', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    washingVeh = true
    QBCore.Functions.Progressbar('search_cabin', Lang:t('wash.in_progress'), math.random(4000, 8000), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleUndriveable(veh, false)
        WashDecalsFromVehicle(veh, 1.0)
        washingVeh = false
    end, function() -- Cancel
        QBCore.Functions.Notify(Lang:t('wash.cancel'), 'error')
        washingVeh = false
    end)
end)

CreateThread(function()
    for k, v in pairs(Config.CarWash.locations) do
        if Config.UseTarget then
            exports["qb-target"]:AddBoxZone('carwash_'..k, v.coords, v.length, v.width, {
                name = 'carwash_'..k,
                debugPoly = false,
                heading = v.heading,
                minZ = v.coords.z - 5,
                maxZ = v.coords.z + 5,
            }, {
                    options = {
                        {
                            icon = "fa-car-wash",
                            label = Lang:t('wash.wash_vehicle_target'),
                            action = function()
                                local ped = PlayerPedId()
                                local veh = GetVehiclePedIsIn(ped, false)
                                local driver = GetPedInVehicleSeat(veh, -1)
                                local dirtLevel = GetVehicleDirtLevel(veh)
                                if driver == ped and not washingVeh then
                                    if dirtLevel > Config.CarWash.dirtLevel then
                                        TriggerServerEvent('qb-carwash:server:washCar')
                                    else
                                        QBCore.Functions.Notify(Lang:t('wash.dirty'), 'error')
                                    end
                                end
                            end,
                            canInteract = function()
                                if IsPedInAnyVehicle(PlayerPedId(), false) then return true end
                            end,
                        }
                    },
                distance = 3
            })
        else
            washPoly[#washPoly + 1] = BoxZone:Create(vector3(v.coords.x, v.coords.y, v.coords.z), v.length, v.width, {
                heading = v.heading,
                name = 'carwash',
                debugPoly = false,
                minZ = v.coords.z - 5,
                maxZ = v.coords.z + 5,
            })
            local washCombo = ComboZone:Create(washPoly, {name = "washPoly"})
            washCombo:onPlayerInOut(function(isPointInside)
                if isPointInside and IsPedInAnyVehicle(PlayerPedId(), false) then
                    exports['qb-core']:DrawText(Lang:t('wash.wash_vehicle'),'left')
                    if not listen then
                        listen = true
                        washLoop()
                    end
                else
                    listen = false
                    exports['qb-core']:HideText()
                end
            end)
        end
    end
end)

CreateThread(function()
    for k in pairs(Config.CarWash.locations) do
        local carWash = AddBlipForCoord(Config.CarWash.locations[k].coords.x, Config.CarWash.locations[k].coords.y, Config.CarWash.locations[k].coords.z)
        SetBlipSprite (carWash, 100)
        SetBlipDisplay(carWash, 4)
        SetBlipScale  (carWash, 0.75)
        SetBlipAsShortRange(carWash, true)
        SetBlipColour(carWash, 37)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Hands Free Carwash')
        EndTextCommandSetBlipName(carWash)
    end
end)

-- === consumables.lua ===
-- Variables
local alcoholCount = 0
local healing, parachuteEquipped = false, false
local currVest, currVestTexture = nil, nil

-- Functions
RegisterNetEvent('QBCore:Client:UpdateObject', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function equipParachuteAnim()
    loadAnimDict('clothingshirt')
    TaskPlayAnim(PlayerPedId(), 'clothingshirt', 'try_shirt_positive_d', 8.0, 1.0, -1, 49, 0, false, false, false)
end

local function healOxy()
    if healing then return end

    healing = true

    local count = 9
    while count > 0 do
        Wait(1000)
        count -= 1
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 6)
    end
    healing = false
end

local function trevorEffect()
    StartScreenEffect('DrugsTrevorClownsFightIn', 3.0, 0)
    Wait(3000)
    StartScreenEffect('DrugsTrevorClownsFight', 3.0, 0)
    Wait(3000)
    StartScreenEffect('DrugsTrevorClownsFightOut', 3.0, 0)
    StopScreenEffect('DrugsTrevorClownsFight')
    StopScreenEffect('DrugsTrevorClownsFightIn')
    StopScreenEffect('DrugsTrevorClownsFightOut')
end

local function methBagEffect()
    local startStamina = 8
    trevorEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    while startStamina > 0 do
        Wait(1000)
        if math.random(5, 100) < 10 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina = startStamina - 1
        if math.random(5, 100) < 51 then
            trevorEffect()
        end
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

local function ecstasyEffect()
    local startStamina = 30
    SetFlash(0, 0, 500, 7000, 500)
    while startStamina > 0 do
        Wait(1000)
        startStamina -= 1
        RestorePlayerStamina(PlayerId(), 1.0)
        if math.random(1, 100) < 51 then
            SetFlash(0, 0, 500, 7000, 500)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
        end
    end
    if IsPedRunning(PlayerPedId()) then
        SetPedToRagdoll(PlayerPedId(), math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
    end
end

local function alienEffect()
    StartScreenEffect('DrugsMichaelAliensFightIn', 3.0, 0)
    Wait(math.random(5000, 8000))
    StartScreenEffect('DrugsMichaelAliensFight', 3.0, 0)
    Wait(math.random(5000, 8000))
    StartScreenEffect('DrugsMichaelAliensFightOut', 3.0, 0)
    StopScreenEffect('DrugsMichaelAliensFightIn')
    StopScreenEffect('DrugsMichaelAliensFight')
    StopScreenEffect('DrugsMichaelAliensFightOut')
end

local function crackBaggyEffect()
    local startStamina = 8
    local ped = PlayerPedId()
    alienEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.3)
    while startStamina > 0 do
        Wait(1000)
        if math.random(1, 100) < 10 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina -= 1
        if math.random(1, 100) < 60 and IsPedRunning(ped) then
            SetPedToRagdoll(ped, math.random(1000, 2000), math.random(1000, 2000), 3, false, false, false)
        end
        if math.random(1, 100) < 51 then
            alienEffect()
        end
    end
    if IsPedRunning(ped) then
        SetPedToRagdoll(ped, math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

local function cokeBaggyEffect()
    local startStamina = 20
    local ped = PlayerPedId()
    alienEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.1)
    while startStamina > 0 do
        Wait(1000)
        if math.random(1, 100) < 20 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina -= 1
        if math.random(1, 100) < 10 and IsPedRunning(ped) then
            SetPedToRagdoll(ped, math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
        end
        if math.random(1, 300) < 10 then
            alienEffect()
            Wait(math.random(3000, 6000))
        end
    end
    if IsPedRunning(ped) then
        SetPedToRagdoll(ped, math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

-- Events

RegisterNetEvent('consumables:client:Eat', function(itemName)
    QBCore.Functions.Progressbar('eat_something', Lang:t('consumables.eat_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mp_player_inteat@burger',
        anim = 'mp_player_int_eat_burger',
        flags = 49
    }, {
        model = 'prop_cs_burger_01',
        bone = 60309,
        coords = vec3(0.0, 0.0, -0.02),
        rotation = vec3(30, 0.0, 0.0),
    }, {}, function() -- Done
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        TriggerServerEvent('consumables:server:addHunger', QBCore.Functions.GetPlayerData().metadata.hunger + Config.Consumables.eat[itemName])
        TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
    end)
end)

RegisterNetEvent('consumables:client:Drink', function(itemName)
    QBCore.Functions.Progressbar('drink_something', Lang:t('consumables.drink_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mp_player_intdrink',
        anim = 'loop_bottle',
        flags = 49
    }, {
        model = 'vw_prop_casino_water_bottle_01a',
        bone = 60309,
        coords = vec3(0.0, 0.0, -0.05),
        rotation = vec3(0.0, 0.0, -40),
    }, {}, function() -- Done
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        TriggerServerEvent('consumables:server:addThirst', QBCore.Functions.GetPlayerData().metadata.thirst + Config.Consumables.drink[itemName])
    end)
end)

RegisterNetEvent('consumables:client:DrinkAlcohol', function(itemName)
    QBCore.Functions.Progressbar('drink_alcohol', Lang:t('consumables.liqour_progress'), math.random(3000, 6000), false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mp_player_intdrink',
        anim = 'loop_bottle',
        flags = 49
    }, {
        model = 'prop_cs_beer_bot_40oz',
        bone = 60309,
        coords = vec3(0.0, 0.0, -0.05),
        rotation = vec3(0.0, 0.0, -40),
    }, {}, function() -- Done
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        TriggerServerEvent('consumables:server:drinkAlcohol', itemName)
        TriggerServerEvent('consumables:server:addThirst', QBCore.Functions.GetPlayerData().metadata.thirst + Config.Consumables.alcohol[itemName])
        TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
        alcoholCount += 1
        AlcoholLoop()
        if alcoholCount > 1 and alcoholCount < 4 then
            TriggerEvent('evidence:client:SetStatus', 'alcohol', 200)
        elseif alcoholCount >= 4 then
            TriggerEvent('evidence:client:SetStatus', 'heavyalcohol', 200)
        end
    end, function() -- Cancel
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:Custom', function(itemName)
    QBCore.Functions.TriggerCallback('consumables:itemdata', function(data)
        QBCore.Functions.Progressbar('custom_consumable', data.progress.label, data.progress.time, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
        }, {
            animDict = data.animation.animDict,
            anim = data.animation.anim,
            flags = data.animation.flags
        }, {
            model = data.prop.model,
            bone = data.prop.bone,
            coords = data.prop.coords,
            rotation = data.prop.rotation
        }, {}, function() -- Done
            ClearPedTasks(PlayerPedId())
            TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
            if data.replenish.type then
                TriggerServerEvent('consumables:server:add' .. data.replenish.type, QBCore.Functions.GetPlayerData().metadata[string.lower(data.replenish.type)] + data.replenish.replenish)
            end
            if data.replenish.isAlcohol then
                alcoholCount += 1
                AlcoholLoop()
                if alcoholCount > 1 and alcoholCount < 4 then
                    TriggerEvent('evidence:client:SetStatus', 'alcohol', 200)
                elseif alcoholCount >= 4 then
                    TriggerEvent('evidence:client:SetStatus', 'heavyalcohol', 200)
                end
            end
            if data.replenish.event then
                TriggerEvent(data.replenish.event)
            end
        end)
    end, itemName)
end)

RegisterNetEvent('consumables:client:Cokebaggy', function()
    local ped = PlayerPedId()
    QBCore.Functions.Progressbar('snort_coke', Lang:t('consumables.coke_progress'), math.random(5000, 8000), false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'switch@trevor@trev_smoking_meth',
        anim = 'trev_smoking_meth_loop',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        TriggerServerEvent('consumables:server:useCokeBaggy')
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['cokebaggy'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'widepupils', 200)
        cokeBaggyEffect()
    end, function() -- Cancel
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:Crackbaggy', function()
    local ped = PlayerPedId()
    QBCore.Functions.Progressbar('snort_coke', Lang:t('consumables.crack_progress'), math.random(7000, 10000), false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'switch@trevor@trev_smoking_meth',
        anim = 'trev_smoking_meth_loop',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        TriggerServerEvent('consumables:server:useCrackBaggy')
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['crack_baggy'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'widepupils', 300)
        crackBaggyEffect()
    end, function() -- Cancel
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:EcstasyBaggy', function()
    QBCore.Functions.Progressbar('use_ecstasy', Lang:t('consumables.ecstasy_progress'), 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mp_suicide',
        anim = 'pill',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        TriggerServerEvent('consumables:server:useXTCBaggy')
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['xtcbaggy'], 'remove')
        ecstasyEffect()
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:oxy', function()
    QBCore.Functions.Progressbar('use_oxy', Lang:t('consumables.healing_progress'), 2000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mp_suicide',
        anim = 'pill',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        TriggerServerEvent('consumables:server:useOxy')
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['oxy'], 'remove')
        ClearPedBloodDamage(PlayerPedId())
        healOxy()
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:meth', function()
    QBCore.Functions.Progressbar('snort_meth', Lang:t('consumables.meth_progress'), 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'switch@trevor@trev_smoking_meth',
        anim = 'trev_smoking_meth_loop',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        TriggerServerEvent('consumables:server:useMeth')
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['meth'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'widepupils', 300)
        TriggerEvent('evidence:client:SetStatus', 'agitated', 300)
        methBagEffect()
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:UseJoint', function()
    QBCore.Functions.Progressbar('smoke_joint', Lang:t('consumables.joint_progress'), 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['joint'], 'remove')
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            QBCore.Functions.PlayAnim('timetable@gardener@smoking_joint', 'smoke_idle', false)
        else
            QBCore.Functions.PlayAnim('timetable@gardener@smoking_joint', 'smoke_idle', false)
        end
        TriggerEvent('evidence:client:SetStatus', 'weedsmell', 300)
        TriggerServerEvent('hud:server:RelieveStress', Config.RelieveWeedStress)
    end)
end)

RegisterNetEvent('consumables:client:UseParachute', function()
    equipParachuteAnim()
    QBCore.Functions.Progressbar('use_parachute', Lang:t('consumables.use_parachute_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        local ped = PlayerPedId()
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['parachute'], 'remove')
        GiveWeaponToPed(ped, `GADGET_PARACHUTE`, 1, false, false)
        local parachuteData = {
            outfitData = { ['bag'] = { item = 7, texture = 0 } } -- Adding Parachute Clothing
        }
        TriggerEvent('qb-clothing:client:loadOutfit', parachuteData)
        parachuteEquipped = true
        TaskPlayAnim(ped, 'clothingshirt', 'exit', 8.0, 1.0, -1, 49, 0, false, false, false)
    end)
end)

RegisterNetEvent('consumables:client:ResetParachute', function()
    if parachuteEquipped then
        equipParachuteAnim()
        QBCore.Functions.Progressbar('reset_parachute', Lang:t('consumables.pack_parachute_progress'), 40000, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            local ped = PlayerPedId()
            TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['parachute'], 'add')
            local parachuteResetData = {
                outfitData = { ['bag'] = { item = 0, texture = 0 } } -- Removing Parachute Clothing
            }
            TriggerEvent('qb-clothing:client:loadOutfit', parachuteResetData)
            TaskPlayAnim(ped, 'clothingshirt', 'exit', 8.0, 1.0, -1, 49, 0, false, false, false)
            TriggerServerEvent('consumables:server:AddParachute')
            parachuteEquipped = false
        end)
    else
        QBCore.Functions.Notify(Lang:t('consumables.no_parachute'), 'error')
    end
end)

RegisterNetEvent('consumables:client:UseArmor', function()
    if GetPedArmour(PlayerPedId()) >= 75 then
        QBCore.Functions.Notify(Lang:t('consumables.armor_full'), 'error')
        return
    end
    QBCore.Functions.Progressbar('use_armor', Lang:t('consumables.armor_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('consumables:server:useArmor')
    end)
end)

RegisterNetEvent('consumables:client:UseHeavyArmor', function()
    if GetPedArmour(PlayerPedId()) == 100 then
        QBCore.Functions.Notify(Lang:t('consumables.armor_full'), 'error')
        return
    end
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    QBCore.Functions.Progressbar('use_heavyarmor', Lang:t('consumables.heavy_armor_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        if not Config.Disable.vestDrawable then
            if PlayerData.charinfo.gender == 0 then
                currVest = GetPedDrawableVariation(ped, 9)
                currVestTexture = GetPedTextureVariation(ped, 9)
                if GetPedDrawableVariation(ped, 9) == 7 then
                    SetPedComponentVariation(ped, 9, 19, GetPedTextureVariation(ped, 9), 2)
                else
                    SetPedComponentVariation(ped, 9, 5, 2, 2)
                end
            else
                currVest = GetPedDrawableVariation(ped, 30)
                currVestTexture = GetPedTextureVariation(ped, 30)
                SetPedComponentVariation(ped, 9, 30, 0, 2)
            end
        end
        TriggerServerEvent('consumables:server:useHeavyArmor')
    end)
end)

RegisterNetEvent('consumables:client:ResetArmor', function()
    local ped = PlayerPedId()
    if currVest ~= nil and currVestTexture ~= nil then
        QBCore.Functions.Progressbar('remove_armor', Lang:t('consumables.remove_armor_progress'), 2500, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            SetPedComponentVariation(ped, 9, currVest, currVestTexture, 2)
            SetPedArmour(ped, 0)
            TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items['heavyarmor'], 'add')
            TriggerServerEvent('consumables:server:resetArmor')
        end)
    else
        QBCore.Functions.Notify(Lang:t('consumables.armor_empty'), 'error')
    end
end)

-- RegisterNetEvent('consumables:client:UseRedSmoke', function()
--     if parachuteEquipped then
--         local ped = PlayerPedId()
--         SetPlayerParachuteSmokeTrailColor(ped, 255, 0, 0)
--         SetPlayerCanLeaveParachuteSmokeTrail(ped, true)
--         TriggerEvent("qs-inventory:client:ItemBox", QBCore.Shared.Items["smoketrailred"], "remove")
--     else
--         QBCore.Functions.Notify("You need to have a paracute to activate smoke!", "error")
--     end
-- end)

--Threads
local looped = false
function AlcoholLoop()
    if not looped then
        looped = true
        CreateThread(function()
            while true do
                Wait(10)
                if alcoholCount > 0 then
                    Wait(1000 * 60 * 15)
                    alcoholCount -= 1
                else
                    looped = false
                    break
                end
            end
        end)
    end
end


-- === crouchprone.lua ===
local isCrouching = false
local walkSet = 'default'

local function loadAnimSet(anim)
    if not HasAnimSetLoaded(anim) then
        RequestAnimSet(anim)
        while not HasAnimSetLoaded(anim) do
            Wait(10)
        end
    end
end

local function resetAnimSet()
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 1.0)
    ResetPedWeaponMovementClipset(ped)
    ResetPedStrafeClipset(ped)

    if walkSet ~= 'default' then
        loadAnimSet(walkSet)
        SetPedMovementClipset(ped, walkSet, 1.0)
        RemoveAnimSet(walkSet)
    end
end

RegisterNetEvent('crouchprone:client:SetWalkSet', function(clipset)
    walkSet = clipset
end)

RegisterCommand('togglecrouch', function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) or IsPedFalling(ped) or IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped) or IsPauseMenuActive() then
        return
    end

    ClearPedTasks(ped)
    if isCrouching then
        resetAnimSet()
        SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
        isCrouching = false
    else
        loadAnimSet('move_ped_crouched')
        SetPedMovementClipset(ped, 'move_ped_crouched', 1.0)
        SetPedStrafeClipset(ped, 'move_ped_crouched_strafing')
        isCrouching = true
    end
end, false)

-- Optional: Register a keybind so they can press CTRL (36) to toggle
RegisterKeyMapping('togglecrouch', 'Toggle Crouch', 'keyboard', 'LCONTROL')


-- === cruise.lua ===
local vehicleClasses = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = true,
    [10] = true,
    [11] = true,
    [12] = true,
    [13] = false,
    [14] = false,
    [15] = false,
    [16] = false,
    [17] = true,
    [18] = true,
    [19] = true,
    [20] = true,
    [21] = false
}

local function triggerCruiseControl(veh)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local speed = GetEntitySpeed(veh)
        if speed > 0 and GetVehicleCurrentGear(veh) > 0 then
            speed = GetEntitySpeed(veh)
            local isTurningOrHandbraking = IsControlPressed(2, 76) or IsControlPressed(2, 63) or IsControlPressed(2, 64)
            TriggerEvent('seatbelt:client:ToggleCruise', true)
            QBCore.Functions.Notify(Lang:t('cruise.activated'))

            CreateThread(function()
                while speed > 0 and GetPedInVehicleSeat(veh, -1) == ped do
                    Wait(0)
                    if not isTurningOrHandbraking and GetEntitySpeed(veh) < speed - 1.5 then
                        speed = 0
                        TriggerEvent('seatbelt:client:ToggleCruise', false)
                        QBCore.Functions.Notify(Lang:t('cruise.deactivated'), 'error')
                        Wait(2000)
                        break
                    end

                    if not isTurningOrHandbraking and IsVehicleOnAllWheels(veh) and GetEntitySpeed(veh) < speed then
                        SetVehicleForwardSpeed(veh, speed)
                    end

                    if IsControlJustPressed(1, 246) then
                        speed = GetEntitySpeed(veh)
                    end

                    if IsControlJustPressed(2, 72) then
                        speed = 0
                        TriggerEvent('seatbelt:client:ToggleCruise', false)
                        QBCore.Functions.Notify(Lang:t('cruise.deactivated'), 'error')
                        Wait(2000)
                        break
                    end
                end
            end)
        end
    end
end

RegisterCommand('togglecruise', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local driver = GetPedInVehicleSeat(veh, -1)
    local vehClass = GetVehicleClass(veh)
    if ped == driver and vehicleClasses[vehClass] then
        triggerCruiseControl(veh)
    end
end, false)

RegisterKeyMapping('togglecruise', 'Toggle Cruise Control', 'keyboard', 'Y')


-- === discord.lua ===
CreateThread(function()
    while Config.Discord.isEnabled do
        SetDiscordAppId(Config.Discord.applicationId)
        SetDiscordRichPresenceAsset(Config.Discord.iconLarge)
        SetDiscordRichPresenceAssetText(Config.Discord.iconLargeHoverText)
        SetDiscordRichPresenceAssetSmall(Config.Discord.iconSmall)
        SetDiscordRichPresenceAssetSmallText(Config.Discord.iconSmallHoverText)

        if Config.Discord.showPlayerCount then
            QBCore.Functions.TriggerCallback('smallresources:server:GetCurrentPlayers', function(result)
                SetRichPresence('Players: ' .. result .. '/' .. Config.Discord.maxPlayers)
            end)
        end

        if Config.Discord.buttons and type(Config.Discord.buttons) == "table" then
            for i, v in pairs(Config.Discord.buttons) do
                SetDiscordRichPresenceAction(i - 1, v.text, v.url)
            end
        end

        Wait(Config.Discord.updateRate)
    end
end)


-- === editor.lua ===
RegisterCommand('record', function()
    StartRecording(1)
    TriggerEvent('QBCore:Notify', Lang:t('editor.started'), 'success')
end, false)

RegisterCommand('clip', function()
    StartRecording(0)
end, false)

RegisterCommand('saveclip', function()
    StopRecordingAndSaveClip()
    TriggerEvent('QBCore:Notify', Lang:t('editor.save'), 'success')
end, false)

RegisterCommand('delclip', function()
    StopRecordingAndDiscardClip()
    TriggerEvent('QBCore:Notify', Lang:t('editor.delete'), 'error')
end, false)

RegisterCommand('editor', function()
    NetworkSessionLeaveSinglePlayer()
    ActivateRockstarEditor()
    TriggerEvent('QBCore:Notify', Lang:t('editor.editor'), 'error')
end, false)


-- === fireworks.lua ===
local fireworkTime = 0
local fireworkLoc = nil
local fireworkList = {
    ['proj_xmas_firework'] = {
        'scr_firework_xmas_ring_burst_rgw',
        'scr_firework_xmas_burst_rgw',
        'scr_firework_xmas_repeat_burst_rgw',
        'scr_firework_xmas_spiral_burst_rgw',
        'scr_xmas_firework_sparkle_spawn'
    },
    ['scr_indep_fireworks'] = {
        'scr_indep_firework_sparkle_spawn',
        'scr_indep_firework_starburst',
        'scr_indep_firework_shotburst',
        'scr_indep_firework_trailburst',
        'scr_indep_firework_trailburst_spawn',
        'scr_indep_firework_burst_spawn',
        'scr_indep_firework_trail_spawn',
        'scr_indep_firework_fountain'
    },
    ['proj_indep_firework'] = {
        'scr_indep_firework_grd_burst',
        'scr_indep_launcher_sparkle_spawn',
        'scr_indep_firework_air_burst',
        'proj_indep_flare_trail'
    },
    ['proj_indep_firework_v2'] = {
        'scr_firework_indep_burst_rwb',
        'scr_firework_indep_spiral_burst_rwb',
        'scr_xmas_firework_sparkle_spawn',
        'scr_firework_indep_ring_burst_rwb',
        'scr_xmas_firework_burst_fizzle',
        'scr_firework_indep_repeat_burst_rwb'
    }
}

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function fireworkText()
    CreateThread(function()
        while true do
            Wait(0)
            if fireworkTime > 0 and fireworkLoc then
                DrawText3D(fireworkLoc.x, fireworkLoc.y, fireworkLoc.z, Lang:t('firework.time_left') .. fireworkTime)
            end
            if fireworkTime <= 0 then break end
        end
    end)
end

local function startFirework(asset, coords)
    fireworkTime = Config.Fireworks.delay
    fireworkLoc = { x = coords.x, y = coords.y, z = coords.z }
    CreateThread(function()
        fireworkText()
        while fireworkTime > 0 do
            Wait(1000)
            fireworkTime -= 1
        end
        UseParticleFxAssetNextCall('scr_indep_fireworks')
        for _ = 1, math.random(5, 10), 1 do
            local firework = fireworkList[asset][math.random(1, #fireworkList[asset])]
            UseParticleFxAssetNextCall(asset)
            StartNetworkedParticleFxNonLoopedAtCoord(firework, fireworkLoc.x, fireworkLoc.y, fireworkLoc.z + 42.5, 0.0, 0.0, 0.0, math.random() * 0.3 + 0.5, false, false, false)
            Wait(math.random() * 500)
        end
        fireworkLoc = nil
    end)
end

CreateThread(function()
    local assets = {
        'scr_indep_fireworks',
        'proj_xmas_firework',
        'proj_indep_firework_v2',
        'proj_indep_firework'
    }

    for i = 1, #assets do
        local asset = assets[i]
        if not HasNamedPtfxAssetLoaded(asset) then
            RequestNamedPtfxAsset(asset)
            while not HasNamedPtfxAssetLoaded(asset) do
                Wait(10)
            end
        end
    end
end)

RegisterNetEvent('fireworks:client:UseFirework', function(itemName, assetName)
    QBCore.Functions.Progressbar('spawn_object', Lang:t('firework.place_progress'), 3000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'anim@narcotics@trash',
        anim = 'drop_front',
        flags = 16,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'anim@narcotics@trash', 'drop_front', 1.0)
        TriggerServerEvent('consumables:server:UseFirework', itemName)
        TriggerEvent('qs-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        local pos = GetEntityCoords(PlayerPedId())
        startFirework(assetName, pos)
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'anim@narcotics@trash', 'drop_front', 1.0)
        QBCore.Functions.Notify(Lang:t('firework.canceled'), 'error')
    end)
end)


-- === handsup.lua ===
local handsUp = false

-- Function to handle control disabling
local function HandleControls()
    CreateThread(function()
        while handsUp do
            for _, control in pairs(Config.HandsUp.controls) do
                DisableControlAction(0, control, true)
            end
            Wait(0)
        end
    end)
end

RegisterCommand(Config.HandsUp.command, function()
    local ped = PlayerPedId()
    if not HasAnimDictLoaded('missminuteman_1ig_2') then
        RequestAnimDict('missminuteman_1ig_2')
        while not HasAnimDictLoaded('missminuteman_1ig_2') do
            Wait(10)
        end
    end
    handsUp = not handsUp
    if exports['qb-policejob']:IsHandcuffed() then return end
    if handsUp then
        TaskPlayAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 8.0, 8.0, -1, 50, 0, false, false, false)
        HandleControls()
    else
        ClearPedTasks(ped)
        -- Controls will be automatically re-enabled when the loop ends
    end
end, false)

RegisterKeyMapping(Config.HandsUp.command, 'Hands Up', 'keyboard', Config.HandsUp.keybind)
exports('getHandsup', function() return handsUp end)
