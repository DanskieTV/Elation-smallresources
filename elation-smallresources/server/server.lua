-- QBCore Initialization
local QBCore = exports['qb-core']:GetCoreObject()

-- === afk.lua ===
RegisterNetEvent('KickForAFK', function()
	DropPlayer(source, Lang:t("afk.kick_message"))
end)

QBCore.Functions.CreateCallback('qb-afkkick:server:GetPermissions', function(source, cb)
    cb(QBCore.Functions.GetPermission(source))
end)


-- === consumables.lua ===
-- Defensive check for Config.Consumables
if not Config then
    print("^1[ERROR] Config is nil! Make sure shared/config.lua is loaded first^7")
    Config = {}
end
if not Config.Consumables then
    print("^1[ERROR] Config.Consumables is nil! Make sure shared/consumables.lua is loaded first^7")
    Config.Consumables = {
        alcohol = {},
        eat = {},
        drink = {},
        custom = {}
    }
end

----------- / alcohol

for k, _ in pairs(Config.Consumables.alcohol or {}) do
    QBCore.Functions.CreateUseableItem(k, function(source, item)
        TriggerClientEvent('consumables:client:DrinkAlcohol', source, item.name)
    end)
end

----------- / Eat

for k, _ in pairs(Config.Consumables.eat) do
    QBCore.Functions.CreateUseableItem(k, function(source, item)
        if not exports['qs-inventory']:RemoveItem(source, item.name, 1, item.slot, 'qb-smallresources:consumables:eat') then return end
        TriggerClientEvent('consumables:client:Eat', source, item.name)
    end)
end

----------- / Drink
for k, _ in pairs(Config.Consumables.drink) do
    QBCore.Functions.CreateUseableItem(k, function(source, item)
        if not exports['qs-inventory']:RemoveItem(source, item.name, 1, item.slot, 'qb-smallresources:consumables:drink') then return end
        TriggerClientEvent('consumables:client:Drink', source, item.name)
    end)
end

----------- / Custom
for k, _ in pairs(Config.Consumables.custom) do
    QBCore.Functions.CreateUseableItem(k, function(source, item)
        if not exports['qs-inventory']:RemoveItem(source, item.name, 1, item.slot, 'qb-smallresources:consumables:custom') then return end
        TriggerClientEvent('consumables:client:Custom', source, item.name)
    end)
end

local function createItem(name, type)
    QBCore.Functions.CreateUseableItem(name, function(source, item)
        if not exports['qs-inventory']:RemoveItem(source, item.name, 1, item.slot, 'qb-smallresources:consumables:createItem') then return end
        TriggerClientEvent('consumables:client:' .. type, source, item.name)
    end)
end
----------- / Drug

QBCore.Functions.CreateUseableItem('joint', function(source, item)
    if not exports['qs-inventory']:RemoveItem(source, item.name, 1, item.slot, 'qb-smallresources:joint') then return end
    TriggerClientEvent('consumables:client:UseJoint', source)
end)

QBCore.Functions.CreateUseableItem('cokebaggy', function(source)
    TriggerClientEvent('consumables:client:Cokebaggy', source)
end)

QBCore.Functions.CreateUseableItem('crack_baggy', function(source)
    TriggerClientEvent('consumables:client:Crackbaggy', source)
end)

QBCore.Functions.CreateUseableItem('xtcbaggy', function(source)
    TriggerClientEvent('consumables:client:EcstasyBaggy', source)
end)

QBCore.Functions.CreateUseableItem('oxy', function(source)
    TriggerClientEvent('consumables:client:oxy', source)
end)

QBCore.Functions.CreateUseableItem('meth', function(source)
    TriggerClientEvent('consumables:client:meth', source)
end)

----------- / Tools

QBCore.Functions.CreateUseableItem('armor', function(source)
    TriggerClientEvent('consumables:client:UseArmor', source)
end)

QBCore.Functions.CreateUseableItem('heavyarmor', function(source)
    TriggerClientEvent('consumables:client:UseHeavyArmor', source)
end)

QBCore.Commands.Add('resetarmor', 'Resets Vest (Police Only)', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == 'police' then
        TriggerClientEvent('consumables:client:ResetArmor', source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'For Police Officer Only', 'error')
    end
end)

QBCore.Functions.CreateUseableItem('binoculars', function(source)
    TriggerClientEvent('binoculars:Toggle', source)
end)

QBCore.Functions.CreateUseableItem('parachute', function(source, item)
    if not exports['qs-inventory']:RemoveItem(source, item.name, 1, item.slot, 'qb-smallresources:parachute') then return end
    TriggerClientEvent('consumables:client:UseParachute', source)
end)

QBCore.Commands.Add('resetparachute', 'Resets Parachute', {}, false, function(source)
    TriggerClientEvent('consumables:client:ResetParachute', source)
end)

----------- / Firework

if Config.Fireworks and Config.Fireworks.items then
    for _, v in pairs(Config.Fireworks.items) do
        QBCore.Functions.CreateUseableItem(v, function(source, item)
            local src = source
            TriggerClientEvent('fireworks:client:UseFirework', src, item.name, 'proj_indep_firework')
        end)
    end
end

----------- / Lockpicking

QBCore.Functions.CreateUseableItem('lockpick', function(source)
    TriggerClientEvent('lockpicks:UseLockpick', source, false)
end)

QBCore.Functions.CreateUseableItem('advancedlockpick', function(source)
    TriggerClientEvent('lockpicks:UseLockpick', source, true)
end)

-- Events for adding and removing specific items to fix some exploits

RegisterNetEvent('consumables:server:AddParachute', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:AddItem(source, 'parachute', 1, false, false, 'consumables:server:AddParachute')
end)

RegisterNetEvent('consumables:server:resetArmor', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:AddItem(source, 'heavyarmor', 1, false, false, 'consumables:server:resetArmor')
end)

RegisterNetEvent('consumables:server:useHeavyArmor', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not exports['E4-INV']:RemoveItem(source, 'heavyarmor', 1, false, 'consumables:server:useHeavyArmor') then return end
    TriggerClientEvent('qs-inventory:client:ItemBox', source, QBCore.Shared.Items['heavyarmor'], 'remove')
    TriggerClientEvent('hospital:server:SetArmor', source, 100)
    SetPedArmour(GetPlayerPed(source), 100)
end)

RegisterNetEvent('consumables:server:useArmor', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not exports['E4-INV']:RemoveItem(source, 'armor', 1, false, 'consumables:server:useArmor') then return end
    TriggerClientEvent('qs-inventory:client:ItemBox', source, QBCore.Shared.Items['armor'], 'remove')
    TriggerClientEvent('hospital:server:SetArmor', source, 75)
    SetPedArmour(GetPlayerPed(source), 75)
end)

RegisterNetEvent('consumables:server:useMeth', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:RemoveItem(source, 'meth', 1, false, 'consumables:server:useMeth')
end)

RegisterNetEvent('consumables:server:useOxy', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:RemoveItem(source, 'oxy', 1, false, 'consumables:server:useOxy')
end)

RegisterNetEvent('consumables:server:useXTCBaggy', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:RemoveItem(source, 'xtcbaggy', 1, false, 'consumables:server:useXTCBaggy')
end)

RegisterNetEvent('consumables:server:useCrackBaggy', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:RemoveItem(source, 'crack_baggy', 1, false, 'consumables:server:useCrackBaggy')
end)

RegisterNetEvent('consumables:server:useCokeBaggy', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    exports['E4-INV']:RemoveItem(source, 'cokebaggy', 1, false, 'consumables:server:useCokeBaggy')
end)

RegisterNetEvent('consumables:server:drinkAlcohol', function(item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local foundItem = nil

    for k in pairs(Config.Consumables.alcohol) do
        if k == item then
            foundItem = k
            break
        end
    end

    if not foundItem then return end
    exports['E4-INV']:RemoveItem(source, foundItem, 1, false, 'consumables:server:drinkAlcohol')
end)

RegisterNetEvent('consumables:server:UseFirework', function(item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local foundItem = nil

    for i = 1, #Config.Fireworks.items do
        if Config.Fireworks.items[i] == item then
            foundItem = Config.Fireworks.items[i]
            break
        end
    end

    if not foundItem then return end
    exports['E4-INV']:RemoveItem(source, foundItem, 1, false, 'consumables:server:UseFirework')
end)

RegisterNetEvent('consumables:server:addThirst', function(amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local currentThirst = Player.PlayerData.metadata.thirst
    local newThirst = math.min(100, currentThirst + amount)
    Player.Functions.SetMetaData('thirst', newThirst)
    TriggerClientEvent('hud:client:UpdateNeeds', source, Player.PlayerData.metadata.hunger, newThirst)
end)

RegisterNetEvent('consumables:server:addHunger', function(amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local currentHunger = Player.PlayerData.metadata.hunger
    local newHunger = math.min(100, currentHunger + amount)
    Player.Functions.SetMetaData('hunger', newHunger)
    TriggerClientEvent('hud:client:UpdateNeeds', source, newHunger, Player.PlayerData.metadata.thirst)
end)

QBCore.Functions.CreateCallback('consumables:itemdata', function(_, cb, itemName)
    cb(Config.Consumables.custom[itemName])
end)

---Checks if item already exists in the table. If not, it creates it.
---@param drinkName string name of item
---@param replenish number amount it replenishes
---@return boolean, string
local function addDrink(drinkName, replenish)
    if Config.Consumables.drink[drinkName] ~= nil then
        return false, 'already added'
    else
        Config.Consumables.drink[drinkName] = replenish
        createItem(drinkName, 'Drink')
        return true, 'success'
    end
end

exports('AddDrink', addDrink)

---Checks if item already exists in the table. If not, it creates it.
---@param foodName string name of item
---@param replenish number amount it replenishes
---@return boolean, string
local function addFood(foodName, replenish)
    if Config.Consumables.eat[foodName] ~= nil then
        return false, 'already added'
    else
        Config.Consumables.eat[foodName] = replenish
        createItem(foodName, 'Eat')
        return true, 'success'
    end
end

exports('AddFood', addFood)

---Checks if item already exists in the table. If not, it creates it.
---@param alcoholName string name of item
---@param replenish number amount it replenishes
---@return boolean, string
local function addAlcohol(alcoholName, replenish)
    if Config.Consumables.alcohol[alcoholName] ~= nil then
        return false, 'already added'
    else
        Config.Consumables.alcohol[alcoholName] = replenish
        createItem(alcoholName, 'DrinkAlcohol')
        return true, 'success'
    end
end

exports('AddAlcohol', addAlcohol)

---Checks if item already exists in the table. If not, it creates it.
---@param itemName string name of item
---@param data number amount it replenishes
---@return boolean, string
local function addCustom(itemName, data)
    if Config.Consumables.custom[itemName] ~= nil then
        return false, 'already added'
    else
        Config.Consumables.custom[itemName] = data
        createItem(itemName, 'Custom')
        return true, 'success'
    end
end

exports('AddCustom', addCustom)


-- === entities.lua ===
-- Blacklisting entities can just be handled entirely server side with onesync events
-- No need to run coroutines to supress or delete these when we can simply delete them before they spawn
AddEventHandler("entityCreating", function(handle)
    local entityModel = GetEntityModel(handle)

    if Config.BlacklistedVehs[entityModel] or Config.BlacklistedPeds[entityModel] then
        CancelEvent()
    end
end)

-- === logs.lua ===
local Webhooks = {
    ['default'] = '',
    ['testwebhook'] = '',
    ['playermoney'] = '',
    ['playerinventory'] = '',
    ['robbing'] = '',
    ['cuffing'] = '',
    ['drop'] = '',
    ['trunk'] = '',
    ['stash'] = '',
    ['glovebox'] = '',
    ['banking'] = '',
    ['vehicleshop'] = '',
    ['vehicleupgrades'] = '',
    ['shops'] = '',
    ['dealers'] = '',
    ['storerobbery'] = '',
    ['bankrobbery'] = '',
    ['powerplants'] = '',
    ['death'] = '',
    ['joinleave'] = '',
    ['ooc'] = '',
    ['report'] = '',
    ['me'] = '',
    ['pmelding'] = '',
    ['112'] = '',
    ['bans'] = '',
    ['anticheat'] = '',
    ['weather'] = '',
    ['moneysafes'] = '',
    ['bennys'] = '',
    ['bossmenu'] = '',
    ['robbery'] = '',
    ['casino'] = '',
    ['traphouse'] = '',
    ['911'] = '',
    ['palert'] = '',
    ['house'] = '',
    ['qbjobs'] = '',
}

local colors = { -- https://www.spycolor.com/
    ['default'] = 14423100,
    ['blue'] = 255,
    ['red'] = 16711680,
    ['green'] = 65280,
    ['white'] = 16777215,
    ['black'] = 0,
    ['orange'] = 16744192,
    ['yellow'] = 16776960,
    ['pink'] = 16761035,
    ['lightgreen'] = 65309,
}

local logQueue = {}

RegisterNetEvent('qb-log:server:CreateLog', function(name, title, color, message, tagEveryone, imageUrl)
    local tag = tagEveryone or false

    if Config.Logging == 'discord' then
        if not Webhooks[name] then
            print('Tried to call a log that isn\'t configured with the name of ' .. name)
            return
        end
        local webHook = Webhooks[name] ~= '' and Webhooks[name] or Webhooks['default']
        local embedData = {
            {
                ['title'] = title,
                ['color'] = colors[color] or colors['default'],
                ['footer'] = {
                    ['text'] = os.date('%c'),
                },
                ['description'] = message,
                ['author'] = {
                    ['name'] = 'QBCore Logs',
                    ['icon_url'] = 'https://raw.githubusercontent.com/GhzGarage/qb-media-kit/main/Display%20Pictures/Logo%20-%20Display%20Picture%20-%20Stylized%20-%20Red.png',
                },
                ['image'] = imageUrl and imageUrl ~= '' and { ['url'] = imageUrl } or nil,
            }
        }

        if not logQueue[name] then logQueue[name] = {} end
        logQueue[name][#logQueue[name] + 1] = { webhook = webHook, data = embedData }

        if #logQueue[name] >= 10 then
            local postData = { username = 'QB Logs', embeds = {} }

            if tag then
                postData.content = '@everyone'
            end

            for i = 1, #logQueue[name] do postData.embeds[#postData.embeds + 1] = logQueue[name][i].data[1] end
            PerformHttpRequest(logQueue[name][1].webhook, function() end, 'POST', json.encode(postData), { ['Content-Type'] = 'application/json' })
            logQueue[name] = {}
        end
    elseif Config.Logging == 'fivemanage' then
        local FiveManageAPIKey = GetConvar('FIVEMANAGE_LOGS_API_KEY', 'false')
        if FiveManageAPIKey == 'false' then
            print('You need to set the FiveManage API key in your server.cfg')
            return
        end
        local extraData = {
            level = tagEveryone and 'warn' or 'info', -- info, warn, error or debug
            message = title,                          -- any string
            metadata = {                              -- a table or object with any properties you want
                description = message,
                playerId = source,
                playerLicense = GetPlayerIdentifierByType(source, 'license'),
                playerDiscord = GetPlayerIdentifierByType(source, 'discord')
            },
            resource = GetInvokingResource(),
        }
        PerformHttpRequest('https://api.fivemanage.com/api/logs', function(statusCode, response, headers)
            -- Uncomment the following line to enable debugging
            -- print(statusCode, response, json.encode(headers))
        end, 'POST', json.encode(extraData), {
            ['Authorization'] = FiveManageAPIKey,
            ['Content-Type'] = 'application/json',
        })
    end
end)

Citizen.CreateThread(function()
    local timer = 0
    while true do
        Wait(1000)
        timer = timer + 1
        if timer >= 60 then -- If 60 seconds have passed, post the logs
            timer = 0
            for name, queue in pairs(logQueue) do
                if #queue > 0 then
                    local postData = { username = 'QB Logs', embeds = {} }
                    for i = 1, #queue do
                        postData.embeds[#postData.embeds + 1] = queue[i].data[1]
                    end
                    PerformHttpRequest(queue[1].webhook, function() end, 'POST', json.encode(postData), { ['Content-Type'] = 'application/json' })
                    logQueue[name] = {}
                end
            end
        end
    end
end)

QBCore.Commands.Add('testwebhook', 'Test Your Discord Webhook For Logs (God Only)', {}, false, function()
    TriggerEvent('qb-log:server:CreateLog', 'testwebhook', 'Test Webhook', 'default', 'Webhook setup successfully')
end, 'god')


-- === main.lua ===
RegisterNetEvent('tackle:server:TacklePlayer', function(playerId)
    TriggerClientEvent('tackle:client:GetTackled', playerId)
end)

QBCore.Commands.Add('id', 'Check Your ID #', {}, false, function(source)
    TriggerClientEvent('QBCore:Notify', source, 'ID: ' .. source)
end)

-- Harness handled by jim-mechanic

-- Harness events handled by jim-mechanic

RegisterNetEvent('qb-carwash:server:washCar', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.Functions.RemoveMoney('cash', Config.CarWash.defaultPrice, 'car-washed') then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    elseif Player.Functions.RemoveMoney('bank', Config.CarWash.defaultPrice, 'car-washed') then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.dont_have_enough_money'), 'error')
    end
end)

QBCore.Functions.CreateCallback('smallresources:server:GetCurrentPlayers', function(_, cb)
    cb(#GetPlayers())
end)


-- === timedjobs.lua ===
-- Variables
local jobs = {}

-- Functions
function GetTime()
	local timestamp = os.time()
	local day = tonumber(os.date('*t', timestamp).wday)
	local hour = tonumber(os.date('%H', timestamp))
	local min = tonumber(os.date('%M', timestamp))

	return {day = day, hour = hour, min = min}
end

function CheckTimes(day, hour, min)
	for i = 1, #jobs, 1 do
		local data = jobs[i]
		if data.hour == hour and data.min == min then
			data.cb(day, hour, min)
		end
	end
end

-- Exports

---Creates a Timed Job
---@param hour number
---@param min number
---@param cb function
exports("CreateTimedJob", function(hour, min, cb)
	if hour and type(hour) == "number" and min and type(min) == "number" and cb and (type(cb) == "function" or type(cb) == "table") then
		jobs[#jobs + 1] = {
			min = min,
			hour = hour,
			cb = cb
		}

		return #jobs
	else
		print("WARN: Invalid arguments for export CreateTimedJob(hour, min, cb)")
		return nil
	end
end)

---Force runs a Timed Job
---@param idx number
exports("ForceRunTimedJob", function(idx)
	if jobs[idx] then
		local time = GetTime()
		jobs[idx].cb(time.day, time.hour, time.min)
	end
end)

---Stops a Timed Job
---@param idx number
exports("StopTimedJob", function(idx)
	if jobs[idx] then
		jobs[idx] = nil
	end
end)

-- Main Loop
CreateThread(function()
	while true do
		local time = GetTime()
		CheckTimes(time.day, time.hour, time.min)

		Wait(60 * 1000)
	end
end)

