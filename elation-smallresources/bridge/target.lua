TargetBridge = {}

-- Check which target system is available
local function getTargetResource()
    if GetResourceState('ox_target') ~= 'missing' then
        return 'ox_target'
    elseif GetResourceState('qb-target') ~= 'missing' then
        return 'qb-target'
    end
    return nil
end

local targetResource = getTargetResource()

function TargetBridge.AddGlobalVehicle(data)
    if not targetResource then return end

    if targetResource == 'ox_target' then
        exports.ox_target:addGlobalVehicle({
            {
                name = data.name or 'unnamed_target',
                icon = data.icon or 'fas fa-hand',
                label = data.label,
                distance = data.distance or 2.5,
                onSelect = data.onSelect,
                canInteract = data.canInteract,
                bones = data.bones,
                options = data.options
            }
        })
    elseif targetResource == 'qb-target' then
        exports['qb-target']:AddGlobalVehicle({
            options = {
                {
                    type = "client",
                    icon = data.icon or 'fas fa-hand',
                    label = data.label,
                    action = data.onSelect,
                    canInteract = data.canInteract
                }
            },
            distance = data.distance or 2.5
        })
    end
end

function TargetBridge.AddTargetEntity(entities, data)
    if not targetResource then return end

    if targetResource == 'ox_target' then
        exports.ox_target:addEntity(entities, {
            {
                name = data.name or 'unnamed_target',
                icon = data.icon or 'fas fa-hand',
                label = data.label,
                distance = data.distance or 2.5,
                onSelect = data.onSelect,
                canInteract = data.canInteract,
                bones = data.bones,
                options = data.options
            }
        })
    elseif targetResource == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entities, {
            options = {
                {
                    type = "client",
                    icon = data.icon or 'fas fa-hand',
                    label = data.label,
                    action = data.onSelect,
                    canInteract = data.canInteract
                }
            },
            distance = data.distance or 2.5
        })
    end
end

function TargetBridge.addTargetEntity(entities, options)
    if not targetResource then return end

    if targetResource == 'ox_target' then
        exports.ox_target:addEntity(entities, options)
    else
        exports['qb-target']:AddTargetEntity(entities, {
            options = options,
            distance = 2.5
        })
    end
end

function TargetBridge.addTargetModel(models, options)
    if not targetResource then return end

    if targetResource == 'ox_target' then
        exports.ox_target:addModel(models, options)
    else
        exports['qb-target']:AddTargetModel(models, {
            options = options,
            distance = 2.5
        })
    end
end

function TargetBridge.removeEntity(entities)
    if not targetResource then return end

    if targetResource == 'ox_target' then
        exports.ox_target:removeEntity(entities)
    else
        exports['qb-target']:RemoveTargetEntity(entities)
    end
end

function TargetBridge.addGlobalVehicle(options)
    if not targetResource then return end

    if targetResource == 'ox_target' then
        exports.ox_target:addGlobalVehicle(options)
    else
        exports['qb-target']:AddGlobalVehicle({
            options = options,
            distance = 2.5
        })
    end
end

return TargetBridge 