----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

local const = require('lib.constants')

---@class logistics_sensor.Mod
---@field remote_apis table<string, string>
---@field settings ff2.ModSettings
---@field SensorController logistics_sensor.Controller
---@field Gui logistics_sensor.Gui?
local This = {
    remote_apis = {
        PickerDollies = 'picker-dollies',
    },
    settings = require('lib.settings'),
}

function This.boot()
    This.SensorController = require('scripts.controller')
    This.Gui = require('scripts.gui')
end

--------------------------------------------------------------------------------
-- Framework initializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function This.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = const.prefix,
        -- prefix for log messages
        log_prefix = const.log_prefix,
        -- name is a human readable name
        name = const.name,
        -- The filesystem root.
        root = const.root,
    }
end

--- Setup the global inventory sensor data structure.
function This:init()
    ---@type logistics_sensor.Storage
    storage.sensor_data = storage.sensor_data or {
        sensors = {},
    }
end

------------------------------------------------------------------------
-- Storage Management
------------------------------------------------------------------------

---@class logistics_sensor.Storage
---@field sensors logistics_sensor.Data[]

---@return logistics_sensor.Storage
function This:storage()
    return assert(storage.sensor_data)
end

return This
