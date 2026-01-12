local commands = require('loop-cmake.commands')

---@param ext_config loop.ExtensionConfig
local function _make_cmd_provider(ext_config)
    ---@type loop.UserCommandProvider
    return {
        get_subcommands = function(args)
            return commands.get_subcommands(args)
        end,
        dispatch = function(args, opts)
            commands.do_command(args, ext_config)
        end
    }
end

---@param ext_config loop.ExtensionConfig
local function _make_task_provider(ext_config)
    ---@type loop.TaskProvider
    return {
        get_task_schema = function()
            local schema = require('loop-cmake.taskschema')
            return schema
        end,
        get_config_order = function()
            local tasks = require('loop-cmake.tasks')
            return tasks.get_config_order()
        end,
        get_task_templates = function()
            local tasks = require('loop-cmake.tasks')
            if not ext_config.have_config_file() then
                vim.notify("Cmake not configured, run :Loop cmake setup_profiles")
                return {}
            end
            local schema = require('loop-cmake.configschema')
            local config = ext_config.load_config_file(schema)
            ---@cast config CMakeConfig
            return tasks.get_tasks(config)
        end,
        start_one_task = function(task, page_manager, on_exit)
        end
    }
end

---@type loop.Extension
local extension =
{
    on_workspace_load = function(ext_data)
        ext_data.register_cmd_provider("cmake", _make_cmd_provider(ext_data.config))
        ext_data.register_task_provider("cmake", _make_task_provider(ext_data.config))
    end,
    on_workspace_unload = function(ext_data)

    end,
}

return extension
