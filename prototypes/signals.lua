------------------------------------------------------------------------
-- Signals
------------------------------------------------------------------------
local const = require('lib.constants')

local function base_icon_png(name)
    return '__base__/graphics/icons/' .. name .. '.png'
end

local signals = {
}

local item_subgroup = {
    type = 'item-subgroup',
    name = 'logistics-sensor-signals',
    group = 'signals',
    order = 'x[logistics-sensor-signals]'
}

data:extend { item_subgroup }
if #signals > 0 then data:extend(signals) end
