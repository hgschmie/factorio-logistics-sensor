---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- sensor.lua
----------------------------------------------------------------------------------------------------

---@class logistics_sensor.DataController
---@field interval scan_frequency
---@field validate (fun(entity: logistics_sensor.Data): boolean)?
---@field contribute (fun(is_data: logistics_sensor.Data, sink: fun(filter: LogisticFilter)))?
---@field signals table<string, integer>?

---@class logistics_sensor.Config
---@field enabled boolean
---@field status defines.entity_status
---@field scan_entity_id integer?

---@class logistics_sensor.Data
---@field sensor_entity LuaEntity
---@field config logistics_sensor.Config
---@field scan_area BoundingBox?
---@field scan_entity LuaEntity?
---@field scan_interval integer?
---@field scan_time integer?
---@field load_time integer?

---@class logistics_sensor.Status

----------------------------------------------------------------------------------------------------
-- controller.lua
----------------------------------------------------------------------------------------------------

---@class logistics_sensor.Storage
---@field sensors logistics_sensor.Data[]
---@field count integer

----------------------------------------------------------------------------------------------------
-- supported_entities.lua
----------------------------------------------------------------------------------------------------
---@class logistics_sensor.SupportedEntities
---@field supported_entities table<string, logistics_sensor.DataController>
---@field blacklist table<string, string>
