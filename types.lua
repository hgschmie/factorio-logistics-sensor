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
---@field validate (fun(entity: LuaEntity): boolean)?
---@field contribute (fun(data: logistics_sensor.Data, sink: fun(filter: LogisticFilter)))?
---@field logistics_points table<defines.logistic_member_index, string>

---@class logistics_sensor.LogisticTypes
---@field logistic_member_index defines.logistic_member_index?
---@field request boolean
---@field pickup boolean
---@field delivery boolean

---@class logistics_sensor.Config
---@field enabled boolean
---@field scan_entity_id integer?
---@field logistic_member_index defines.logistic_member_index?
---@field selected logistics_sensor.LogisticTypes

---@class logistics_sensor.State
---@field status defines.entity_status
---@field logistics_points string[]
---@field supported logistics_sensor.LogisticTypes[]
---@field reset_on_connect boolean
---@field reconnect_key string?

---@class logistics_sensor.Data
---@field sensor_entity LuaEntity
---@field config logistics_sensor.Config
---@field state logistics_sensor.State
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
