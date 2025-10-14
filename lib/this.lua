----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class logistics_sensor.Mod
---@field other_mods table<string, string>
---@field SensorController logistics_sensor.Controller
---@field Gui logistics_sensor.Gui?
This = {
    other_mods = {
        ['even-pickier-dollies'] = 'picker-dollies',
    },
}

Framework.settings:add_defaults(require('lib.settings'))

if script then
    This.SensorController = require('scripts.controller')
    This.Gui = require('scripts.gui')
end

return This
