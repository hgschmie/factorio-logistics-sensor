------------------------------------------------------------------------
-- Sensor prototype
------------------------------------------------------------------------

local util = require('util')
local table = require('stdlib.utils.table')

local const = require('lib.constants')

local item_prototype = {
    name = const.logistics_sensor_name,
    icon = const:png('item/logistics-sensor'),
    icon_size = 64,
    place_result = const.logistics_sensor_name,
    order = const.order,
}

---@type data.ItemPrototype
local ls_item = table.merge(util.copy(data.raw.item['constant-combinator']), item_prototype)

------------------------------------------------------------------------

local entity_prototype = {

    -- PrototypeBase
    name = const.logistics_sensor_name,
    order = const.order,

    -- ConstantCombinatorPrototype
    sprites = make_4way_animation_from_spritesheet {
        layers =
        {
            {
                scale = 0.5,
                filename = const:png('entity/logistics-sensor'),
                width = 114,
                height = 102,
                shift = util.by_pixel(0, 5)
            },
            {
                scale = 0.5,
                filename = '__base__/graphics/entity/combinator/constant-combinator-shadow.png',
                width = 98,
                height = 66,
                shift = util.by_pixel(8.5, 5.5),
                draw_as_shadow = true
            }
        }
    },

    -- EntityPrototype
    icon = const:png('item/logistics-sensor'),
    minable = { mining_time = 0.1, result = const.logistics_sensor_name },
}

---@type data.ConstantCombinatorPrototype
local ls_entity = table.merge(util.copy(data.raw['constant-combinator']['constant-combinator']), entity_prototype)

data:extend { ls_item, ls_entity }
