------------------------------------------------------------------------
-- Logistics Sensor Data Management
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

local Area = require('stdlib.area.area')
local Direction = require('stdlib.area.direction')
local Position = require('stdlib.area.position')
local table = require('stdlib.utils.table')

---@type logistics_sensor.SupportedEntities
local sensor_entities = require('scripts.supported-entities')

------------------------------------------------------------------------

---@type logistics_sensor.LogisticTypes
local NO_TYPE_SUPPORTED = {
    request = false,
    pickup = false,
    delivery = false,
}

---@type logistics_sensor.TypeConfig
local DEFAULT_TYPE_ENABLED = {
    enabled = false,
    mode = 'quantity',
    inverted = false,
}

------------------------------------------------------------------------

---@class logistics_sensor.Sensor
---@field scan_offset number
---@field scan_range number
local LogisticsSensor = {
    ---@enum logistics_sensor.Type
    TYPES = {
        pickup = 'pickup',
        delivery = 'delivery',
        request = 'request',
    },

    scan_offset = Framework.settings:startup_setting(const.settings_scan_offset_name),
    scan_range = Framework.settings:startup_setting(const.settings_scan_range_name),
}

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

---@param entity LuaEntity?
---@return logistics_sensor.ScanController?
local function locate_scan_controller(entity)
    if not (entity and entity.valid) then return nil end
    assert(entity)

    local scan_controller = sensor_entities.supported_entities[entity.type] and
        (sensor_entities.supported_entities[entity.type][entity.name] or sensor_entities.supported_entities[entity.type]['*'])

    if not scan_controller then return nil end

    -- if there is a validate function, it must pass
    if scan_controller.validate and not scan_controller.validate(entity) then return nil end

    return scan_controller
end

--------------------------------------------------------------------------------
-- configure
--------------------------------------------------------------------------------

---@param entity LuaEntity?
---@return string?
local function get_entity_key(entity)
    if not (entity and entity.valid) then return nil end

    return entity.type .. '__' .. entity.name
end

---@param sensor_data logistics_sensor.Data
---@param scan_controller logistics_sensor.ScanController
function LogisticsSensor.update_supported(sensor_data, scan_controller)
    if not (sensor_data.scan_entity and sensor_data.scan_entity.valid) then return end

    -- turn everything off first
    sensor_data.state.supported = {}
    sensor_data.state.logistics_points = {}

    -- update the available logistics points
    local logistics_points = sensor_data.scan_entity.get_logistic_point()
    local new_logistic_member_index = nil
    for _, logistics_point in pairs(logistics_points) do
        local logistic_member_index = logistics_point.logistic_member_index

        if scan_controller.logistics_points[logistic_member_index] then
            -- select the very first index as default
            if not new_logistic_member_index then
                new_logistic_member_index = logistic_member_index
            end
            -- if the currently selected index is supported, then use that as default
            if logistic_member_index == sensor_data.config.logistic_member_index then
                new_logistic_member_index = logistic_member_index
            end

            table.insert(sensor_data.state.logistics_points, scan_controller.logistics_points[logistic_member_index])

            local supported = util.copy(const.supported_logistic_modes[logistics_point.mode])
            supported.logistic_member_index = logistic_member_index
            table.insert(sensor_data.state.supported, supported)
        end
    end

    sensor_data.config.logistic_member_index = new_logistic_member_index
    sensor_data.state.reset_on_connect = true
    sensor_data.state.reconnect_key = get_entity_key(sensor_data.scan_entity)
end

---@param sensor_data logistics_sensor.Data
---@param config logistics_sensor.Config?
function LogisticsSensor.reconfigure(sensor_data, config)
    if not config then return end

    sensor_data.config.enabled = config.enabled
    sensor_data.config.selected = util.copy(config.selected)
    sensor_data.config.logistic_member_index = config.logistic_member_index
end

----------------------------------------------------------------------------------------------------
-- create/destroy
----------------------------------------------------------------------------------------------------

--
-- logistics sensor states
--
-- "create" -> creates entity
-- "scan" -> look for entities to connect to.
-- "connect" -> choose an entity, serve status from it
-- "disconnect" -> either through entity deleted, sensor or entity moved out of range
--

---@param sensor_entity LuaEntity
---@param config logistics_sensor.Config?
---@return logistics_sensor.Data
function LogisticsSensor.new(sensor_entity, config)
    ---@type logistics_sensor.Data
    local data = {
        sensor_entity = sensor_entity,
        config = {
            enabled = true,
            selected = {
                request = util.copy(DEFAULT_TYPE_ENABLED),
                pickup = util.copy(DEFAULT_TYPE_ENABLED),
                delivery = util.copy(DEFAULT_TYPE_ENABLED),
            },
        },
        state = {
            status = sensor_entity.status,
            -- if a config was provided, do not reset state at next connect
            -- this allows blueprints to work
            reset_on_connect = not config,
            supported = {},
            logistics_points = {},
        },
    }

    if config then LogisticsSensor.reconfigure(data, config) end

    return data
end

---@param sensor_data logistics_sensor.Data
function LogisticsSensor.destroy(sensor_data)
    if not sensor_data then return end
    sensor_data.sensor_entity = nil -- don't destroy; lifecycle is managed by the game and destroying prevents ghosts from showing
end

---@param sensor_data logistics_sensor.Data
---@param unit_number integer
function LogisticsSensor.validate(sensor_data, unit_number)
    return sensor_data.sensor_entity and sensor_data.sensor_entity.valid and sensor_data.sensor_entity.unit_number == unit_number
end

----------------------------------------------------------------------------------------------------
-- scan
----------------------------------------------------------------------------------------------------

---@param entity LuaEntity
---@return boolean
local function sensor_horizontal(entity)
    return entity.direction == defines.direction.west or entity.direction == defines.direction.east
end

---@param sensor_data logistics_sensor.Data
---@return BoundingBox scan_area
function LogisticsSensor.create_scan_area(sensor_data)
    assert(sensor_data.sensor_entity)

    local entity = sensor_data.sensor_entity
    local position = Position(entity.position)
    local area = Area.new {
        position + { -0.5, -LogisticsSensor.scan_offset },
        position + { 0.5, LogisticsSensor.scan_offset }
    }
    area = sensor_horizontal(entity) and area or area:flip()
    area = area:translate(Direction.opposite(entity.direction), LogisticsSensor.scan_range - 0.5)

    return area
end

---@param sensor_data logistics_sensor.Data
---@param force boolean?
---@return boolean scanned True if scan happened
function LogisticsSensor.scan(sensor_data, force)
    if sensor_data.config.enabled then
        local interval = sensor_data.scan_interval or Framework.settings:runtime_setting(const.settings_find_entity_interval_name)

        local scan_time = sensor_data.scan_time or 0
        if not (force or (game.tick - scan_time >= interval)) then return false end

        sensor_data.scan_time = game.tick

        -- if force is set, always create the scan area, otherwise, if a scan area
        -- already exists, use that
        sensor_data.scan_area = (not force) and sensor_data.scan_area or LogisticsSensor.create_scan_area(sensor_data)

        if Framework.settings:startup_setting('debug_mode') then
            rendering.draw_rectangle {
                color = { r = 0.5, g = 0.5, b = 1 },
                surface = sensor_data.sensor_entity.surface,
                left_top = sensor_data.scan_area.left_top,
                right_bottom = sensor_data.scan_area.right_bottom,
                time_to_live = 10,
            }
        end

        local entities = sensor_data.sensor_entity.surface.find_entities(sensor_data.scan_area)

        for _, entity in pairs(entities) do
            if LogisticsSensor.connect(sensor_data, entity) then return true end
        end
    end

    -- not connected
    LogisticsSensor.disconnect(sensor_data)

    return true
end

----------------------------------------------------------------------------------------------------
-- load/clear
----------------------------------------------------------------------------------------------------


---@param sensor_data  logistics_sensor.Data
---@return logistics_sensor.LogisticTypes supported
---@return integer idx
function LogisticsSensor.find_supported(sensor_data)
    if sensor_data.config.logistic_member_index then
        for idx, supported in pairs(sensor_data.state.supported) do
            if supported.logistic_member_index == sensor_data.config.logistic_member_index then return supported, idx end
        end
    end

    return NO_TYPE_SUPPORTED, 0
end

---@param sensor_data logistics_sensor.Data
---@return LuaLogisticSection
function LogisticsSensor.get_section(sensor_data)
    -- empty the signals sections

    local control = assert(sensor_data.sensor_entity.get_or_create_control_behavior()) --[[@as LuaConstantCombinatorControlBehavior ]]
    if control.sections_count == 0 then control.add_section() end

    return assert(control.get_section(1))
end

---@type table<logistics_sensor.Type, fun(logistic_point: LuaLogisticPoint, sink_func: fun(filter: LogisticFilter), result_func: fun(number): number)>
local READ_DATA = {
    pickup = function(logistics_point, sink_func, result_func)
        for _, item in pairs(logistics_point.targeted_items_pickup) do
            sink_func { value = { name = item.name, type = 'item', quality = item.quality or 'normal' }, min = result_func(item.count) }
        end
    end,
    delivery = function(logistics_point, sink_func, result_func)
        for _, item in pairs(logistics_point.targeted_items_deliver) do
            sink_func { value = { name = item.name, type = 'item', quality = item.quality or 'normal' }, min = result_func(item.count) }
        end
    end,
    request = function(logistics_point, sink_func, result_func)
        for _, request_section in pairs(logistics_point.sections) do
            if request_section.active then
                for _, filter in pairs(request_section.filters) do
                    sink_func { value = { name = filter.value.name, type = 'item', quality = filter.value.quality or 'normal' }, min = result_func(filter.min) }
                end
            end
        end
    end,
}

--- Loads the state of the connected entity into the sensor.
---@param sensor_data logistics_sensor.Data
---@param force boolean?
---@return boolean entity was loaded
function LogisticsSensor.load(sensor_data, force)
    local load_time = sensor_data.load_time or 0
    if not (force or (game.tick - load_time >= Framework.settings:runtime_setting(const.settings_update_interval_name))) then return false end
    sensor_data.load_time = game.tick

    local section = LogisticsSensor.get_section(sensor_data)
    section.filters = {}

    if not sensor_data.config.enabled then return false end
    local scan_entity = sensor_data.scan_entity
    if not (scan_entity and scan_entity.valid) then return false end

    local scan_controller = locate_scan_controller(scan_entity)
    if not scan_controller then return false end

    ---@type table<string, number>
    local cache = {}

    ---@type LogisticFilter[]
    local filters = {}

    ---@type fun(filter: LogisticFilter)
    local sink = function(filter)
        if filter.min == 0 then return end

        local signal = assert(filter.value)
        local key = ('%s:%s:%s'):format(signal.name, signal.type or 'item', signal.quality or 'normal')
        local index = cache[key]
        if not index then
            table.insert(filters, filter)
            cache[key] = #filters
        else
            filters[index].min = filters[index].min + filter.min
        end
    end

    if sensor_data.config.logistic_member_index then
        local logistics_point = scan_entity.get_logistic_point(sensor_data.config.logistic_member_index)
        if logistics_point then
            local supported_types = assert(LogisticsSensor.find_supported(sensor_data))

            for report_type in pairs(LogisticsSensor.TYPES) do
                ---@type boolean
                local supported = supported_types[report_type] or false
                local selected = assert(sensor_data.config.selected[report_type])

                if supported and selected.enabled then
                    local result_function = function(value)
                        if selected.mode == 'one' and value > 0 then value = 1 end
                        if selected.inverted then value = -value end
                        return value
                    end

                    READ_DATA[report_type](logistics_point, sink, result_function)
                end
            end
        end
    end

    -- add custom signals
    if scan_controller.contribute then
        scan_controller.contribute(sensor_data, sink)
    end

    if Framework.settings:startup_setting('debug_mode') then
        rendering.draw_rectangle {
            color = { r = 1, g = 1, b = 0.3 },
            surface = sensor_data.sensor_entity.surface,
            left_top = sensor_data.sensor_entity.bounding_box.left_top,
            right_bottom = sensor_data.sensor_entity.bounding_box.right_bottom,
            time_to_live = 2,
        }
    end

    section.filters = filters

    return true
end

----------------------------------------------------------------------------------------------------
-- connect/disconnect
----------------------------------------------------------------------------------------------------

---@param sensor_data logistics_sensor.Data
---@param entity LuaEntity
---@return boolean connected
function LogisticsSensor.connect(sensor_data, entity)
    if not (entity and entity.valid) then return false end
    if sensor_entities.blacklist[entity.name] then return false end

    -- reconnect to the same entity
    if sensor_data.scan_entity and sensor_data.scan_entity.valid and sensor_data.scan_entity.unit_number == entity.unit_number then return true end

    local scan_controller = locate_scan_controller(entity)
    if not scan_controller then return false end

    sensor_data.scan_entity = entity
    sensor_data.scan_interval = scan_controller.interval or scan_frequency.stationary -- unset scan interval -> stationary

    sensor_data.config.scan_entity_id = entity.unit_number

    local entity_key = get_entity_key(entity)

    if sensor_data.state.reset_on_connect and not (sensor_data.state.reconnect_key and entity_key == sensor_data.state.reconnect_key) then
        sensor_data.config.logistic_member_index = nil
        for report_type in pairs(LogisticsSensor.TYPES) do
            sensor_data.config.selected[report_type].enabled = false
        end
    end

    sensor_data.state.reconnect_key = entity_key

    -- update the list of supported logistics points for the entity.
    -- Not all entities support all possible logistics points (e.g. cargo landing pad outside space age)
    LogisticsSensor.update_supported(sensor_data, scan_controller)

    LogisticsSensor.load(sensor_data, true)

    if Framework.settings:startup_setting('debug_mode') then
        rendering.draw_rectangle {
            color = { r = 0.3, g = 1, b = 0.3 },
            surface = sensor_data.sensor_entity.surface,
            left_top = sensor_data.scan_area.left_top,
            right_bottom = sensor_data.scan_area.right_bottom,
            time_to_live = 10,
        }
    end

    return true
end

---@param sensor_data logistics_sensor.Data
function LogisticsSensor.disconnect(sensor_data)
    if not sensor_data.scan_entity then return end

    sensor_data.scan_entity = nil
    sensor_data.scan_interval = nil
    sensor_data.scan_time = nil
    sensor_data.load_time = nil

    sensor_data.config.scan_entity_id = nil
    sensor_data.state.status = nil
    sensor_data.state.logistics_points = {}
    sensor_data.state.supported = {}

    local section = LogisticsSensor.get_section(sensor_data)
    section.filters = {}

    if Framework.settings:startup_setting('debug_mode') then
        rendering.draw_rectangle {
            color = { r = 1, g = 0.3, b = 0.3 },
            surface = sensor_data.sensor_entity.surface,
            left_top = sensor_data.scan_area.left_top,
            right_bottom = sensor_data.scan_area.right_bottom,
            time_to_live = 10,
        }
    end
end

----------------------------------------------------------------------------------------------------
-- ticker
----------------------------------------------------------------------------------------------------

---@param sensor_data logistics_sensor.Data
---@return boolean if entity was either scanned or loaded
function LogisticsSensor.tick(sensor_data)
    if not (sensor_data.sensor_entity and sensor_data.sensor_entity.valid) then
        sensor_data.config.enabled = false
        sensor_data.state.status = defines.entity_status.marked_for_deconstruction
        return false
    else
        sensor_data.state.status = sensor_data.sensor_entity.status

        local scanned = LogisticsSensor.scan(sensor_data)
        local loaded = LogisticsSensor.load(sensor_data)
        return scanned or loaded
    end
end

----------------------------------------------------------------------------------------------------

return LogisticsSensor
