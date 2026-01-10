local commands = require('loop-cmake.commands')

---@type loop.UserCommandProvider
local cmd_provider = {
     get_subcommands = function (args)
        return commands.get_subcommands(args)
     end,
     dispatch = function (args, opts)
        commands.do_command(args)
     end
}

---@type loop.TaskProvider
local task_provider = {
    get_config_schema = function()
        local schema = require('loop-cmake.configschema')
        return schema
    end,
    get_config_template = function()
        local template = require('loop-cmake.configtemplate')
        return template
    end,
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
        return tasks.get_tasks()
    end,
    start_one_task = function(task, page_manager, on_exit)
    end
}

---@type loop.Extension
local extension =
{
     on_workspace_load = function (ws, store)
        
     end,
     on_workspace_unload = function (ws)
        
     end,
    get_cmd_provider = function()
        return cmd_provider
    end,
    get_task_provider = function()
        return task_provider
    end,
}

return extension
