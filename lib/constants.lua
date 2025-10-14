------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------

---@enum scan_frequency
scan_frequency = {
    stationary = 300, -- scan every five seconds
    mobile = 30,      -- scan every 1/2 of a second
    empty = 120       -- scan every 2 seconds
}

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

Constants.signal_names = {
}

Constants.signals = {}
for name, signal in pairs(Constants.signal_names) do
    Constants.signals[name] = { type = 'virtual', name = signal, quality = 'normal' }
end

Constants.logistics_status_signals = {
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
