local M = {}

---@param task loop-cmake.Task
---@param page_manager loop.PageManager
---@param on_exit loop.TaskExitHandler
---@return loop.TaskControl|nil
---@return string|nil
function M.start_app(task, page_manager, on_exit)
    --[[
    -- Your original args — unchanged, just using the resolved values
    ---@type loop.tools.TermProc.StartArgs
    local start_args = {
        name = task.name or "Unnamed Tool Task",
        command = task.command,
        env = task.env,
        cwd = task.cwd or projinfo.proj_dir,
        output_handler = nil,
        on_exit_handler = function(code)
            if code == 0 then
                on_exit(true, nil)
            else
                on_exit(false, "Exit code " .. tostring(code))
            end
        end,
    }

    local pagegroup = page_manager.get_page_group(task.type)
    if not pagegroup then
        pagegroup = page_manager.add_page_group(task.type, "Run")
    end

    local proc, err_msg = pagegroup.add_term_page(task.name, start_args, true)
    if not proc then
        return nil, err_msg
    end

    ---@type loop.TaskControl
    local controller = {
        is_running = function()
            return proc:is_running()
        end,
        terminate = function()
            proc:kill()
        end
    }
    return controller, nil
    ]]
    return nil, "not implemented"
end

return M
