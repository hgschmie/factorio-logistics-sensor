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

------------------------------------------------------------------------
-- Defined entity types
------------------------------------------------------------------------

-- generic container
local container_type = {
    interval = scan_frequency.stationary,
}

------------------------------------------------------------------------

---@type table<string, logistics_sensor.DataController|table<string, logistics_sensor.DataController>>
local supported_entities = {
    -- container-ish
    ['logistic-container'] = util.copy(container_type),
}

------------------------------------------------------------------------

---@type table<string, string>
local blacklisted_entities = table.array_to_dictionary {
}

local supported_entity_map = {}

-- normalize map. For any type that has no sub-name, use '*' as a wild card
for type, map in pairs(supported_entities) do
    local type_map = {}

    if map.interval then
        type_map['*'] = map
    else
        for name, name_map in pairs(map) do
            type_map[name] = name_map
        end
    end

    supported_entity_map[type] = type_map
end

------------------------------------------------------------------------

return {
    supported_entities = supported_entity_map,
    blacklist = blacklisted_entities
}
