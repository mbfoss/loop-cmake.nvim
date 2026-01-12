local M = {}

local workspace = require('loop.workspace')
local tasks = require('loop-cmake.tasks')

function M.get_subcommands(args)
    if #args == 0 then
        return { "setup_profiles", "configure" }
    end
    return {}
end

---@param args string[]
---@param ext_config loop.ExtensionConfig
function M.do_command(args, ext_config)
    if #args == 0 then return end
    if args[1] == "setup_profiles" then
        local template = require('loop-cmake.configtemplate')
        local schema = require('loop-cmake.configschema')
        ext_config.init_config_file(template, schema)
        return
    end
    if args[1] == "configure" then
        if not ext_config.have_config_file() then
            vim.notify("Cmake not configured, run :Loop cmake setup_profiles")
            return {}
        end
        local schema = require('loop-cmake.configschema')
        local config = ext_config.load_config_file(schema)
        ---@cast config CMakeConfig
        local task_list, root_or_err = tasks.get_configure_tasks(config)
        if not task_list or not root_or_err then
            vim.notify(root_or_err or "Failed to build configure tasks")
        else
            local root_name = root_or_err
            workspace.run_custom_task(task_list, root_name)
        end
        return
    end
end

return M
