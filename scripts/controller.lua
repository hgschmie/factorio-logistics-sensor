------------------------------------------------------------------------
-- Logistics Sensor main code
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

local Sensor = require('scripts.sensor')

------------------------------------------------------------------------

---@class logistics_sensor.Controller
local LogisticsSensorController = {}

------------------------------------------------------------------------
-- init setup
------------------------------------------------------------------------

--- Setup the global logistics sensor data structure.
function LogisticsSensorController:init()
    storage.sensor_data = storage.sensor_data or {
        sensors = {},
        count = 0,
    } --[[@as logistics_sensor.Storage ]]
end

------------------------------------------------------------------------
-- attribute getters/setters
------------------------------------------------------------------------

--- Returns the registered total count.
---@return integer count The total count of logistics sensors
function LogisticsSensorController:totalCount()
    return storage.sensor_data.count
end

--- Returns data for all logistics sensors.
---@return logistics_sensor.Data[] entities
function LogisticsSensorController:entities()
    return storage.sensor_data.sensors
end

--- Returns data for a given logistics sensor
---@param entity_id integer main unit number (== entity id)
---@return logistics_sensor.Data? entity
function LogisticsSensorController:entity(entity_id)
    return storage.sensor_data.sensors[entity_id]
end

--- Sets or clears a logistics sensor entity
---@param entity_id integer The unit_number of the primary
---@param sensor_data logistics_sensor.Data?
function LogisticsSensorController:setEntity(entity_id, sensor_data)
    assert((sensor_data ~= nil and storage.sensor_data.sensors[entity_id] == nil) or sensor_data == nil)

    if (sensor_data) then assert(Sensor.validate(sensor_data, entity_id)) end

    storage.sensor_data.sensors[entity_id] = sensor_data
    storage.sensor_data.count = storage.sensor_data.count + ((sensor_data and 1) or -1)

    if storage.sensor_data.count < 0 then
        storage.sensor_data.count = table_size(storage.sensor_data.sensors)
        Framework.logger:logf('Logistics Sensor count got negative (bug), count is now: %d', storage.sensor_data.count)
    end
end

------------------------------------------------------------------------
-- creation
------------------------------------------------------------------------

---@param main_entity LuaEntity
---@param config logistics_sensor.Config?
function LogisticsSensorController:create(main_entity, config)
    main_entity.rotatable = true

    local sensor_data = Sensor.new(main_entity, config)
    self:setEntity(main_entity.unit_number, sensor_data)

    -- initial scan when created
    Sensor.scan(sensor_data)
end

------------------------------------------------------------------------
-- deletion
------------------------------------------------------------------------

--@param unit_number integer
function LogisticsSensorController:destroy(unit_number)
    assert(unit_number)

    local sensor_data = self:entity(unit_number)
    if not sensor_data then return end

    Sensor.destroy(sensor_data)
    self:setEntity(unit_number, nil)
end

------------------------------------------------------------------------
-- rotate / move
------------------------------------------------------------------------

--@param unit_number integer
function LogisticsSensorController:move(unit_number)
    local sensor_data = self:entity(unit_number)
    if not sensor_data then return end

    Sensor.scan(sensor_data, true)
end

--------------------------------------------------------------------------------
-- serialization for Blueprinting and Tombstones
--------------------------------------------------------------------------------

---@param entity LuaEntity
---@return table<string, any>?
function LogisticsSensorController.serialize_config(entity)
    if not (entity and entity.valid) then return end

    local sensor_data = This.SensorController:entity(entity.unit_number)
    if not sensor_data then return end

    return {
        [const.config_tag_name] = sensor_data.config,
    }
end

----------------------------------------------------------------------------------------------------

return LogisticsSensorController
