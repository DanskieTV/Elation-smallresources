Config = {}

-- Initialize all config sections to prevent nil errors
Config.AFK = { ignoredGroups = {} }
Config.BlacklistedVehs = {}
Config.BlacklistedPeds = {}
Config.Objects = {}
Config.Fireworks = {}
Config.ignoredGroups = {}

-- Initialize Consumables with default empty categories
Config.Consumables = {
    alcohol = {},
    eat = {},
    drink = {},
    custom = {}
}

local function loadConfigFile(filePath)
    print("^2[DEBUG] Attempting to load: " .. filePath .. "^7")
    
    local chunk = LoadResourceFile(GetCurrentResourceName(), filePath)
    if not chunk then
        print("^1[elation-smallresources] WARNING: Could not load config file: " .. filePath .. "^7")
        return false
    end

    local fn, err = load(chunk)
    if not fn then
        print("^1[elation-smallresources] ERROR: Failed to parse config file: " .. filePath .. " - " .. (err or "unknown error") .. "^7")
        return false
    end

    local success, result = pcall(fn)
    if not success then
        print("^1[elation-smallresources] ERROR: Failed to execute config file: " .. filePath .. " - " .. (result or "unknown error") .. "^7")
        return false
    end

    if type(result) ~= "table" then
        print("^1[elation-smallresources] ERROR: Config file did not return a table: " .. filePath .. "^7")
        return false
    end

    for k, v in pairs(result) do
        Config[k] = v
    end
    
    print("^2[DEBUG] Successfully loaded: " .. filePath .. "^7")
    return true
end

-- List of config files to load
local configFiles = {
    "config/afk.lua",
    "config/handsup.lua",
    "config/binoculars.lua",
    "config/ai_response.lua",
    "config/discord.lua",
    "config/density.lua",
    "config/disable.lua",
    "config/coresettings.lua",
    "config/language.lua",
    "config/fireworks.lua",
    "config/blacklisted_scenarios.lua",
    "config/blacklisted_vehs.lua",
    "config/blacklisted_weapons.lua",
    "config/blacklisted_peds.lua",
    "config/objects.lua",
    "config/carwash.lua",
    "config/teleports.lua"
}

-- Load all config files
for _, file in ipairs(configFiles) do
    loadConfigFile(file)
end

-- Load consumables
local consumablesChunk = LoadResourceFile(GetCurrentResourceName(), "shared/consumables.lua")
if consumablesChunk then
    local fn, err = load(consumablesChunk)
    if fn then
        local success, result = pcall(fn)
        if success and type(result) == "table" then
            -- Merge consumables data
            for category, items in pairs(result) do
                if Config.Consumables[category] then
                    for item, data in pairs(items) do
                        Config.Consumables[category][item] = data
                    end
                end
            end
            print("^2[elation-smallresources] Successfully loaded consumables^7")
        else
            print("^1[elation-smallresources] ERROR: Failed to execute consumables.lua - " .. (result or "unknown error") .. "^7")
        end
    else
        print("^1[elation-smallresources] ERROR: Failed to load consumables.lua - " .. (err or "unknown error") .. "^7")
    end
else
    print("^1[elation-smallresources] WARNING: Could not load shared/consumables.lua^7")
end

-- After loading all configs, set the backward compatibility values
if Config.AFK and Config.AFK.ignoredGroups then
    Config.ignoredGroups = Config.AFK.ignoredGroups
end 