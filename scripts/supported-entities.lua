------------------------------------------------------------------------
-- Supported entities / blacklist
------------------------------------------------------------------------
assert(script)

local util = require('util')
local table = require('stdlib.utils.table')

local const = require('lib.constants')

------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------

local has_space_age = script.active_mods['space-age'] and true or false

---@param entity LuaEntity
---@return boolean
local function is_stopped(entity)
    if not (entity and entity.valid) then return false end
    return entity.speed == 0 -- entity must be standing still
end

------------------------------------------------------------------------
-- Defined entity types
------------------------------------------------------------------------

-- generic container
---@type logistics_sensor.ScanController
local container_type = {
    interval = const.scan_frequency.stationary,
    validate = function(entity)
        return entity.prototype.logistic_mode and entity.prototype.logistic_mode ~= 'none' or false
    end,
    logistics_points = {
        [defines.logistic_member_index.logistic_container] = const.logistics_point_names.main,
        [defines.logistic_member_index.logistic_container_trash_provider] = const.logistics_point_names.trash,
    }
}

---@type logistics_sensor.ScanController
local cargo_pad_type = {
    interval = const.scan_frequency.stationary,
    logistics_points = {
        -- https://forums.factorio.com/viewtopic.php?t=131341
        [defines.logistic_member_index.space_platform_hub_requester] = const.logistics_point_names.space_platform_deliveries,
        [defines.logistic_member_index.space_platform_hub_provider] = const.logistics_point_names.main,
        [defines.logistic_member_index.rocket_silo_trash_provider] = const.logistics_point_names.trash,
    }
}

---@type logistics_sensor.ScanController
local roboport_type = {
    interval = const.scan_frequency.stationary,
    logistics_points = {
        [defines.logistic_member_index.roboport_provider] = const.logistics_point_names.repair_packs,
    }
}

---@type logistics_sensor.ScanController
local rocket_silo_type = {
    --- only works in space-age
    validate = function()
        return has_space_age
    end,
    interval = const.scan_frequency.stationary,
    logistics_points = {
        [defines.logistic_member_index.rocket_silo_provider] = const.logistics_point_names.rocket_inventory,
        [defines.logistic_member_index.rocket_silo_requester] = const.logistics_point_names.main,
        [defines.logistic_member_index.rocket_silo_trash_provider] = const.logistics_point_names.trash,
    }
}

---@type logistics_sensor.ScanController
local space_platform_hub_type = {
    interval = const.scan_frequency.stationary,
    logistics_points = {
        [defines.logistic_member_index.space_platform_hub_requester] = const.logistics_point_names.request_for_construction,
        [defines.logistic_member_index.space_platform_hub_provider] = const.logistics_point_names.provider,
    }
}

---@type logistics_sensor.ScanController
local car_type = {
    interval = const.scan_frequency.mobile,
    validate = is_stopped,
    logistics_points = {
        [defines.logistic_member_index.car_requester] = const.logistics_point_names.vehicle_logistics,
        [defines.logistic_member_index.car_provider] = const.logistics_point_names.trash,
    }
}

---@type logistics_sensor.ScanController
local spidertron_type = {
    interval = const.scan_frequency.mobile,
    validate = is_stopped,
    logistics_points = {
        [defines.logistic_member_index.spidertron_requester] = const.logistics_point_names.vehicle_logistics,
        [defines.logistic_member_index.spidertron_provider] = const.logistics_point_names.trash,
    }
}

------------------------------------------------------------------------

---@type table<string, logistics_sensor.ScanController|table<string, logistics_sensor.ScanController>>
local supported_entities = {
    -- container-ish
    ['logistic-container'] = util.copy(container_type),
    ['infinity-container'] = util.copy(container_type),

    ['cargo-landing-pad'] = util.copy(cargo_pad_type),

    ['roboport'] = util.copy(roboport_type),

    ['rocket-silo'] = util.copy(rocket_silo_type),

    ['space-platform-hub'] = util.copy(space_platform_hub_type),

    -- mobile units
    car = util.copy(car_type),
    ['spider-vehicle'] = util.copy(spidertron_type),
}

------------------------------------------------------------------------

---@type table<string, string>
local blacklisted_entities = table.array_to_dictionary {
}

local supported_entity_map = {}

-- normalize map. For any type that has no sub-name, use '*' as a wild card
for entity_type, map in pairs(supported_entities) do
    local type_map = {}

    if map.interval then
        type_map['*'] = map
    else
        for name, name_map in pairs(map) do
            type_map[name] = name_map
        end
    end

    supported_entity_map[entity_type] = type_map
end

------------------------------------------------------------------------

return {
    supported_entities = supported_entity_map,
    blacklist = blacklisted_entities
}
