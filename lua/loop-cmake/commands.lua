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
function M.do_command(args)
    if #args == 0 then return end
    if args[1] == "setup_profiles" then
        vim.notify("Not implemented")
        return
    end
    if args[1] == "configure" then
        local task_list, root_or_err = tasks.get_configure_tasks()
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
