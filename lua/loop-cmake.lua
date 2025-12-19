local run = require('loop-cmake.run')

---@type loop.TaskProvider
local provider = {
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
    get_config_order = function ()
        local tasks = require('loop-cmake.tasks')
        return tasks.get_config_order()
    end,
    get_task_templates = function(config)
        ---@cast config CMakeConfig
        local tasks = require('loop-cmake.tasks')
        return tasks.get_tasks(config)
    end,
    start_one_task = run.start_build
}

return provider
