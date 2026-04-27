------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------

local Constants = {}

--------------------------------------------------------------------------------
-- main constants
--------------------------------------------------------------------------------

Constants.prefix = 'hps__ls-'
Constants.name = 'logistics-sensor'
Constants.root = '__logistics-sensor__'
Constants.gfx_location = Constants.root .. '/graphics/'
Constants.order = 'c[combinators]-d[logistics-sensor]'
Constants.config_tag_name = 'ls_config'

--------------------------------------------------------------------------------
-- Framework initializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function Constants.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = Constants.prefix,
        -- name is a human readable name
        name = Constants.name,
        -- The filesystem root.
        root = Constants.root,
    }
end

--------------------------------------------------------------------------------
-- Path and name helpers
--------------------------------------------------------------------------------

---@param value string
---@return string result
function Constants:with_prefix(value)
    return self.prefix .. value
end

---@param path string
---@return string result
function Constants:png(path)
    return self.gfx_location .. path .. '.png'
end

---@param id string
---@return string result
function Constants:locale(id)
    return Constants:with_prefix('gui.') .. id
end

--------------------------------------------------------------------------------
-- entity names and maps
--------------------------------------------------------------------------------

-- Base name
Constants.logistics_sensor_name = Constants:with_prefix(Constants.name)

--------------------------------------------------------------------------------
-- enabled / disabled gui fields
--------------------------------------------------------------------------------

---@type table<defines.logistic_mode, logistics_sensor.LogisticTypes>
Constants.supported_logistic_modes = {
    [defines.logistic_mode.none] = {
        request = false,
        pickup = false,
        delivery = false,
    },
    [defines.logistic_mode.active_provider] = {
        request = false,
        pickup = true,
        delivery = false,
    },
    [defines.logistic_mode.storage] = {
        request = false,
        pickup = true,
        delivery = true,
    },
    [defines.logistic_mode.requester] = {
        request = true,
        pickup = false,
        delivery = true,
    },
    [defines.logistic_mode.passive_provider] = {
        request = false,
        pickup = true,
        delivery = false,
    },
    [defines.logistic_mode.buffer] = {
        request = true,
        pickup = true,
        delivery = true,
    },
}

Constants.logistics_point = {
    main = { Constants:locale('logistics-main') },
    trash = { Constants:locale('logistics-trash') },
    provider = { Constants:locale('logistics-provider') },
    requester = { Constants:locale('logistics-requester') },
    vehicle_logistics = { Constants:locale('logistics-vehicle-logistics') },
    repair_packs = { Constants:locale('logistics-repair-packs') },
    rocket_inventory = { Constants:locale('logistics-rocket-inventory') },
    request_for_construction = { Constants:locale('logistics-request-for-construction') },
    space_platform_deliveries = { Constants:locale('logistics-space-platform-deliveries') },
}

Constants.logistics_point_names = {}
for key, _ in pairs(Constants.logistics_point) do
    Constants.logistics_point_names[key] = key
end

---@enum scan_frequency
Constants.scan_frequency = {
    stationary = 300, -- scan every five seconds
    mobile = 30,      -- scan every 1/2 of a second
    empty = 120       -- scan every 2 seconds
}


--------------------------------------------------------------------------------
-- settings
--------------------------------------------------------------------------------

Constants.settings_update_interval_name = 'update_interval'
Constants.settings_find_entity_interval_name = 'find_entity_interval'
Constants.settings_scan_offset_name = 'scan_offset'
Constants.settings_scan_range_name = 'scan_range'

Constants.settings_update_interval = Constants:with_prefix(Constants.settings_update_interval_name)
Constants.settings_find_entity_interval = Constants:with_prefix(Constants.settings_find_entity_interval_name)
Constants.settings_scan_offset = Constants:with_prefix(Constants.settings_scan_offset_name)
Constants.settings_scan_range = Constants:with_prefix(Constants.settings_scan_range_name)

--------------------------------------------------------------------------------
return Constants
