local workspace = require('loop.workspace')
local tasks = require('loop-cmake.tasks')

---@private
---@param value any
---@param wsdir string
---@return any
local function _replace_wsdir_in_value(value, wsdir)
    if type(value) ~= "string" then
        return value
    end

    -- Non-printable placeholder (ASCII Unit Separator)
    local placeholder = string.char(31) .. "WS_DIR" .. string.char(31)

    -- Protect escaped occurrences ($${wsdir})
    value = value:gsub("%$%${wsdir}", placeholder)

    -- Replace real occurrences (${wsdir})
    value = value:gsub("%${wsdir}", wsdir)

    -- Restore escaped ones as literal ${wsdir}
    value = value:gsub(placeholder, "${wsdir}")

    return value
end

---@param tbl table
---@param wsdir string
---@return table
local function replace_wsdir_recursive(tbl, wsdir)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            replace_wsdir_recursive(v, wsdir)
        else
            tbl[k] = _replace_wsdir_in_value(v, wsdir)
        end
    end

    return tbl
end

local function _get_subcommands(args)
    if #args == 0 then
        return { "setup_profiles", "configure" }
    end
    return {}
end

---@param args string[]
---@param ext_data loop.ExtensionData
local function _do_command(args, ext_data)
    if #args == 0 then return end
    if args[1] == "setup_profiles" then
        local template = require('loop-cmake.configtemplate')
        local schema = require('loop-cmake.configschema')
        ext_data.config.init_config_file(template, schema)
        return
    end
    if args[1] == "configure" then
        if not ext_data.config.have_config_file() then
            vim.notify("Cmake profiles not configured, run :Loop cmake setup_profiles")
            return {}
        end
        local schema = require('loop-cmake.configschema')
        local config = ext_data.config.load_config_file(schema)
        if not config then
            vim.notify("Cmake profiles configuration missing, run :Loop cmake setup_profiles")
            return {}
        end
        replace_wsdir_recursive(config, ext_data.ws_dir)
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

---@param ext_data loop.ExtensionData
local function _make_cmd_provider(ext_data)
    ---@type loop.UserCommandProvider
    return {
        get_subcommands = function(args)
            return _get_subcommands(args)
        end,
        dispatch = function(args, opts)
            _do_command(args, ext_data)
        end
    }
end

---@param ext_data loop.ExtensionData
local function _make_template_provider(ext_data)
    ---@type loop.TaskTemplateProvider
    return {
        get_task_templates = function()
            if not ext_data.config.have_config_file() then
                vim.notify("Cmake not configured, run :Loop cmake setup_profiles")
                return {}
            end
            local schema = require('loop-cmake.configschema')
            local config = ext_data.config.load_config_file(schema)
            if not config then
                vim.notify("Cmake configuration missing, run :Loop cmake setup_profiles")
                return {}
            end
            replace_wsdir_recursive(config, ext_data.ws_dir)
            ---@cast config CMakeConfig
            return tasks.get_tasks(config)
        end,
    }
end

---@type loop.Extension
local extension =
{
    on_workspace_load = function(ext_data)
        ext_data.register_user_command("cmake", _make_cmd_provider(ext_data))
        ext_data.register_task_templates("CMake", _make_template_provider(ext_data))
    end,
    on_workspace_unload = function(ext_data)

    end,
}

return extension
