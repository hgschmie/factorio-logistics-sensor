require('lib.init')

local const = require('lib.constants')

data:extend {
    {
        type = 'int-setting',
        name = const.settings_update_interval,
        order = 'aa',
        setting_type = 'runtime-global',
        default_value = 10,
        minimum_value = 5,
        maximum_value = 216000, -- 1h
    },
    {
        type = 'int-setting',
        name = const.settings_find_entity_interval,
        order = 'ab',
        setting_type = 'runtime-global',
        default_value = 120,
        minimum_value = 5,
        maximum_value = 216000, -- 1h
    },
    {
        type = 'double-setting',
        name = const.settings_scan_offset,
        order = 'aa',
        setting_type = 'startup',
        default_value = 0.2,
    },
    {
        type = 'double-setting',
        name = const.settings_scan_range,
        order = 'ab',
        setting_type = 'startup',
        default_value = 1.5,
    },
    {
        -- Debug mode (framework dependency)
        type = 'bool-setting',
        name = Framework.PREFIX .. 'debug-mode',
        order = 'bb',
        setting_type = 'startup',
        default_value = false,
    },
}

--------------------------------------------------------------------------------

Framework.post_settings_stage()
