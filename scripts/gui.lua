------------------------------------------------------------------------
-- Logistics Sensor GUI
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local table = require('stdlib.utils.table')

local tools = require('framework.tools')
local Matchers = require('framework.matchers')
local signal_converter = require('framework.signal_converter')

local const = require('lib.constants')

local Sensor = require('scripts.sensor')

local GUI_NAME = 'logistics-combinator-gui'

---@class logistics_sensor.Gui
local Gui = {}

----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

--- Provides all the events used by the GUI and their mappings to functions. This must be outside the
--- GUI definition as it can not be serialized into storage.
---@return framework.gui_manager.event_definition
local function get_gui_event_definition()
    return {
        events = {
            onWindowClosed = Gui.onWindowClosed,
            onSwitchEnabled = Gui.onSwitchEnabled,
            onToggleReportSelect = Gui.onToggleReportSelect,
            onToggleChangeRequestMode = Gui.onToggleChangeRequestMode,
            onToggleRequestInvert = Gui.onToggleRequestInvert,
            onLogisticPointChanged = Gui.onLogisticPointChanged,
        },
        callback = Gui.guiUpdater,
    }
end

---@param gui framework.gui
---@param report_type logistics_sensor.Type The report type (e.g., 'pickups', 'deliveries', 'requests')
---@return framework.gui.element_definition[]
local function get_report_gui(gui, report_type)
    local report_name = 'report-' .. report_type

    return {
        {
            type = 'checkbox',
            caption = { const:locale(report_name) },
            name = report_name .. '-select',
            elem_tags = { report_type = report_type },
            handler = { [defines.events.on_gui_checked_state_changed] = gui.gui_events.onToggleReportSelect },
            state = false,
        },
        {
            type = 'flow',
            direction = 'vertical',
            children = {
                {
                    type = 'radiobutton',
                    caption = { '', { const:locale('report-quantity') }, ' [img=info]' },
                    tooltip = { const:locale('report-quantity-description') },
                    name = report_name .. '-quantity',
                    elem_tags = {
                        report_type = report_type,
                        report_state = 'quantity',
                    },
                    handler = { [defines.events.on_gui_checked_state_changed] = gui.gui_events.onToggleChangeRequestMode },
                    state = false,
                },
                {
                    type = 'radiobutton',
                    caption = { const:locale('report-one') },
                    name = report_name .. '-one',
                    elem_tags = {
                        report_type = report_type,
                        report_state = 'one',
                    },
                    handler = { [defines.events.on_gui_checked_state_changed] = gui.gui_events.onToggleChangeRequestMode },
                    state = false,
                },
            }
        },
        {
            type = 'checkbox',
            caption = { '', { const:locale('report-invert') }, ' [img=info]' },
            tooltip = { const:locale('report-invert-description') },
            name = report_name .. '-invert',
            elem_tags = { report_type = report_type },
            handler = { [defines.events.on_gui_checked_state_changed] = gui.gui_events.onToggleRequestInvert },
            state = false,
        },
    }
end

--- Returns the definition of the GUI. All events must be mapped onto constants from the gui_events array.
---@param gui framework.gui
---@return framework.gui.element_definition ui
function Gui.getUi(gui)
    local gui_events = gui.gui_events

    local sensor_data = This.SensorController:entity(gui.entity_id)
    assert(sensor_data)

    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = gui_events.onWindowClosed },
        elem_mods = { auto_center = true },
        children = {
            { -- Title Bar
                type = 'flow',
                style = 'frame_header_flow',
                drag_target = 'gui_root',
                children = {
                    {
                        type = 'label',
                        style = 'frame_title',
                        caption = { 'entity-name.' .. const.logistics_sensor_name },
                        drag_target = 'gui_root',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'empty-widget',
                        style = 'framework_titlebar_drag_handle',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'sprite-button',
                        style = 'frame_action_button',
                        sprite = 'utility/close',
                        hovered_sprite = 'utility/close_black',
                        clicked_sprite = 'utility/close_black',
                        mouse_button_filter = { 'left' },
                        tooltip = { 'gui.close-instruction' },
                        handler = { [defines.events.on_gui_click] = gui_events.onWindowClosed },
                    },
                },
            }, -- Title Bar End
            {  -- Body
                type = 'frame',
                style = 'entity_frame',
                style_mods = { width = 424, },
                children = {
                    {
                        type = 'flow',
                        style = 'two_module_spacing_vertical_flow',
                        direction = 'vertical',
                        children = {
                            {
                                type = 'frame',
                                direction = 'horizontal',
                                style = 'framework_subheader_frame',
                                children = {
                                    {
                                        type = 'label',
                                        style = 'subheader_label',
                                        name = 'connections',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'connection-red',
                                        visible = false,
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'connection-green',
                                        visible = false,
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { horizontally_stretchable = true },
                                    },
                                },
                            },
                            {
                                type = 'flow',
                                style = 'framework_indicator_flow',
                                children = {
                                    {
                                        type = 'sprite',
                                        name = 'entity-lamp',
                                        style = 'framework_indicator',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'entity-status',
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { horizontally_stretchable = true },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        caption = { const:locale('id'), sensor_data.sensor_entity.unit_number },
                                    },
                                },
                            },
                            {
                                type = 'frame',
                                style = 'deep_frame_in_shallow_frame',
                                name = 'preview_frame',
                                children = {
                                    {
                                        type = 'entity-preview',
                                        name = 'preview',
                                        style = 'wide_entity_button',
                                        elem_mods = { entity = sensor_data.sensor_entity },
                                    },
                                },
                            },
                            {
                                type = 'label',
                                style = 'semibold_label',
                                caption = { 'gui-constant.output' },
                            },
                            {
                                type = 'switch',
                                name = 'on-off',
                                right_label_caption = { 'gui-constant.on' },
                                left_label_caption = { 'gui-constant.off' },
                                handler = { [defines.events.on_gui_switch_state_changed] = gui_events.onSwitchEnabled },
                            },
                            {
                                type = 'flow',
                                style = 'framework_indicator_flow',
                                children = {
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { const:locale('status-label') },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'status',
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { horizontally_stretchable = true },
                                    },
                                },
                            },
                            {
                                type = 'drop-down',
                                name = 'logistic-point',
                                handler = { [defines.events.on_gui_selection_state_changed] = gui_events.onLogisticPointChanged },
                                items = {},
                            },
                            {
                                type = 'table',
                                column_count = 3,
                                style_mods = {
                                    top_margin = -8,         -- pull the table a bit closer to the label above
                                    horizontal_spacing = 24, -- space the elements in the table out
                                },
                                children = table.flatten {
                                    get_report_gui(gui, Sensor.TYPES.pickup),
                                    get_report_gui(gui, Sensor.TYPES.delivery),
                                    get_report_gui(gui, Sensor.TYPES.request),
                                },
                            },
                            {
                                type = 'scroll-pane',
                                style = 'deep_slots_scroll_pane',
                                direction = 'vertical',
                                name = 'signal-view-pane',
                                visible = true,
                                vertical_scroll_policy = 'auto-and-reserve-space',
                                horizontal_scroll_policy = 'never',
                                style_mods = {
                                    horizontally_stretchable = true,
                                },
                                children = {
                                    {
                                        type = 'table',
                                        style = 'filter_slot_table',
                                        name = 'signal-view',
                                        column_count = 10,
                                        style_mods = {
                                            vertical_spacing = 4,
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

---@param gui framework.gui
---@param sensor_data logistics_sensor.Data?
function Gui.render_preview(gui, sensor_data)
    if not sensor_data then return end

    local signal_view = gui:findElement('signal-view')
    assert(signal_view)

    signal_view.clear()
    local section = Sensor.get_section(sensor_data)

    for _, filter in pairs(section.filters) do
        local button = signal_view.add {
            type = 'sprite-button',
            style = 'compact_slot',
            number = filter.min,
            quality = filter.value.quality,
            sprite = signal_converter:logistic_filter_to_sprite_name(filter),
            tooltip = signal_converter:logistic_filter_to_prototype(filter).localised_name,
            elem_tooltip = signal_converter:logistic_filter_to_elem_id(filter),
        }
    end
end

----------------------------------------------------------------------------------------------------
-- UI Callbacks
----------------------------------------------------------------------------------------------------

--- close the UI (button or shortcut key)
---
---@param event EventData.on_gui_click|EventData.on_gui_closed
---@param gui framework.gui
function Gui.onWindowClosed(event, gui)
    Framework.gui_manager:destroyGui(event.player_index, gui.type)
end

local on_off_values = {
    left = false,
    right = true,
}

local values_on_off = table.invert(on_off_values)

--- Enable / Disable switch
---
---@param event EventData.on_gui_switch_state_changed
---@param gui framework.gui
function Gui.onSwitchEnabled(event, gui)
    local sensor_data = This.SensorController:entity(gui.entity_id)
    if not sensor_data then return end

    sensor_data.config.enabled = on_off_values[event.element.switch_state]
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleReportSelect(event, gui)
    local sensor_data = This.SensorController:entity(gui.entity_id)
    if not sensor_data then return end

    local selected = assert(sensor_data.config.selected[event.element.tags.report_type])
    selected.enabled = event.element.state
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleChangeRequestMode(event, gui)
    local sensor_data = This.SensorController:entity(gui.entity_id)
    if not sensor_data then return end

    local selected = assert(sensor_data.config.selected[event.element.tags['report_type']])
    if event.element.state then selected.mode = assert(event.element.tags.report_state) end
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onToggleRequestInvert(event, gui)
    local sensor_data = This.SensorController:entity(gui.entity_id)
    if not sensor_data then return end

    local selected = assert(sensor_data.config.selected[event.element.tags.report_type])
    selected.inverted = event.element.state
end

---@param event EventData.on_gui_selection_state_changed
---@param gui framework.gui
function Gui.onLogisticPointChanged(event, gui)
    local sensor_data = This.SensorController:entity(gui.entity_id)
    if not sensor_data then return end

    ---@type defines.logistic_member_index?
    local new_index
    if event.element.selected_index > 0 then
        local supported = sensor_data.state.supported[event.element.selected_index]
        if supported then new_index = supported.logistic_member_index end
    end

    sensor_data.config.logistic_member_index = new_index
end

----------------------------------------------------------------------------------------------------
-- GUI state updater
----------------------------------------------------------------------------------------------------

---@param sensor_data logistics_sensor.Data
---@return LocalisedString[]
local function localize_items(sensor_data)
    local items = {}
    for key, value in pairs(sensor_data.state.logistics_points) do
        items[key] = const.logistics_point[value]
    end
    return items
end

---@param gui framework.gui
---@param sensor_data logistics_sensor.Data
---@param report_type logistics_sensor.Type The report type (e.g., 'pickups', 'deliveries', 'requests')
local function update_report_gui(gui, sensor_data, report_type)
    local report_name = 'report-' .. report_type
    local selected = assert(sensor_data.config.selected[report_type])
    local supported = Sensor.find_supported(sensor_data)

    local enabled = (sensor_data.config.logistic_member_index and supported[report_type]) or false

    local report_select = assert(gui:findElement(report_name .. '-select'))
    report_select.enabled = enabled
    report_select.state = enabled and selected.enabled or false

    local report_quantity = assert(gui:findElement(report_name .. '-quantity'))
    report_quantity.enabled = enabled
    report_quantity.state = (enabled and selected.mode == 'quantity') or false

    local report_one = assert(gui:findElement(report_name .. '-one'))
    report_one.enabled = enabled
    report_one.state = (enabled and selected.mode == 'one') or false

    local report_invert = assert(gui:findElement(report_name .. '-invert'))
    report_invert.enabled = enabled
    report_invert.state = enabled and selected.inverted or false
end

---@param gui framework.gui
---@param sensor_data logistics_sensor.Data
local function update_config_gui_state(gui, sensor_data)
    local sensor_status = (not sensor_data.config.enabled) and defines.entity_status.disabled -- if not enabled, status is disabled
        or sensor_data.state.status                                                           -- if enabled, the registered state takes precedence if present
        or defines.entity_status.working                                                      -- otherwise, it is working

    local entity_lamp = gui:findElement('entity-lamp')
    entity_lamp.sprite = tools.STATUS_SPRITES[sensor_status]

    local entity_status = gui:findElement('entity-status')
    entity_status.caption = { tools.STATUS_NAMES[sensor_status] }

    local supported, idx = Sensor.find_supported(sensor_data)

    local logistic_point = assert(gui:findElement('logistic-point'))
    logistic_point.enabled = #sensor_data.state.logistics_points > 0
    logistic_point.items = localize_items(sensor_data)
    logistic_point.selected_index = idx

    update_report_gui(gui, sensor_data, Sensor.TYPES.pickup)
    update_report_gui(gui, sensor_data, Sensor.TYPES.delivery)
    update_report_gui(gui, sensor_data, Sensor.TYPES.request)

    local status = gui:findElement('status')
    if sensor_data.config.enabled then
        if (sensor_data.scan_entity and sensor_data.scan_entity.valid) then
            status.caption = { const:locale('reading'), sensor_data.scan_entity.localised_name, sensor_data.scan_entity.unit_number }
        else
            status.caption = { const:locale('scanning') }
        end
    else
        status.caption = { const:locale('disabled') }
    end

    local enabled = sensor_data.config.enabled
    local on_off = gui:findElement('on-off')
    on_off.switch_state = values_on_off[enabled]
end

---@param gui framework.gui
---@param sensor_data logistics_sensor.Data
local function update_gui_state(gui, sensor_data)
    Gui.render_preview(gui, sensor_data)

    local connections = gui:findElement('connections')
    connections.caption = { 'gui-control-behavior.not-connected' }
    for _, color in pairs { 'red', 'green' } do
        local wire_connector = sensor_data.sensor_entity.get_wire_connector(defines.wire_connector_id['circuit_' .. color], false)

        local wire_connection = gui:findElement('connection-' .. color)
        if wire_connector and wire_connector.connection_count > 0 then
            connections.caption = { 'gui-control-behavior.connected-to-network' }
            wire_connection.visible = true
            wire_connection.caption = { 'gui-control-behavior.' .. color .. '-network-id', wire_connector.network_id }
        else
            wire_connection.visible = false
            wire_connection.caption = nil
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Event ticker
----------------------------------------------------------------------------------------------------

---@param gui framework.gui
---@return boolean
function Gui.guiUpdater(gui)
    local sensor_data = This.SensorController:entity(gui.entity_id)
    if not sensor_data then return false end

    ---@type logistics_sensor.GuiContext
    local context = gui.context

    if not (context.last_config and table.compare(context.last_config, sensor_data.config))
        or not (context.last_state and table.compare(context.last_state, sensor_data.state)) then
        update_config_gui_state(gui, sensor_data)
        context.last_config = util.copy(sensor_data.config)
        context.last_state = util.copy(sensor_data.state)
    end

    -- always update wire state and preview
    update_gui_state(gui, sensor_data)

    return true
end

----------------------------------------------------------------------------------------------------
-- open gui handler
----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
function Gui.onGuiOpened(event)
    local player = Player.get(event.player_index)
    if not player then return end

    local entity = event and event.entity --[[@as LuaEntity]]
    if not entity then
        player.opened = nil
        return
    end

    assert(entity.unit_number)
    local sensor_data = This.SensorController:entity(entity.unit_number)

    if not sensor_data then
        log('Data missing for ' ..
            event.entity.name .. ' on ' .. event.entity.surface.name .. ' at ' .. serpent.line(event.entity.position) .. ' refusing to display UI')
        player.opened = nil
        return
    end

    ---@class logistics_sensor.GuiContext
    ---@field last_config logistics_sensor.Config?
    ---@field last_state logistics_sensor.State?
    local gui_state = {
        last_config = nil,
        last_state = nil,
    }

    local gui = Framework.gui_manager:createGui {
        type = GUI_NAME,
        player_index = event.player_index,
        parent = player.gui.screen,
        ui_tree_provider = Gui.getUi,
        context = gui_state,
        entity_id = entity.unit_number
    }

    player.opened = gui.root
end

function Gui.onGhostGuiOpened(event)
    local player = Player.get(event.player_index)
    if not player then return end

    player.opened = nil
end

----------------------------------------------------------------------------------------------------
-- Event registration
----------------------------------------------------------------------------------------------------

local function init_gui()
    Framework.gui_manager:registerGuiType(GUI_NAME, get_gui_event_definition())

    local match_logistics_sensor = Matchers:matchEventEntityName(const.logistics_sensor_name)
    local match_ghost_logistics_sensor = Matchers:matchEventEntityGhostName(const.logistics_sensor_name)

    Event.on_event(defines.events.on_gui_opened, Gui.onGuiOpened, match_logistics_sensor)
    Event.on_event(defines.events.on_gui_opened, Gui.onGhostGuiOpened, match_ghost_logistics_sensor)
end

Event.on_init(init_gui)
Event.on_load(init_gui)

return Gui
