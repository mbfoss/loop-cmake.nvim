local filetools = require('loop.tools.file')
local logs = require('loop.logs')
local jsoncodec = require('loop.json.codec')
local jsonvalidator = require('loop.json.validator')
local JsonEditor = require('loop.json.JsonEditor')

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

---@param ext_data loop.ExtensionData
local function _setup_profiles(ext_data)
    local schema = require('loop-cmake.configschema')

    local filepath = ext_data.get_config_file_path("profiles")
    local schema_filepath = ext_data.get_config_file_path("profilesschema")
    if not filetools.file_exists(filepath) then
        if not filetools.file_exists(schema_filepath) then
            jsoncodec.save_to_file(schema_filepath, schema)
        end
        local data = vim.fn.deepcopy(require('loop-cmake.configtemplate'))
        data["$schema"] = "./" .. vim.fn.fnamemodify(schema_filepath, ":t")
        jsoncodec.save_to_file(filepath, data)
    end

    local editor = JsonEditor:new({
        name = "CMake profiles configuration",
        filepath = filepath,
        schema = schema,
    })

    editor:open()
    editor:save()
end

---@param ext_data loop.ExtensionData
local function _load_ext_config(ext_data)
    local filepath = ext_data.get_config_file_path("profiles")
    local schema = require('loop-cmake.configschema')
    if not filetools.file_exists(filepath) then
        vim.notify("Cmake profiles not configured, run :Loop cmake setup_profiles")
        return
    end
    local loaded, config_or_err = jsoncodec.load_from_file(filepath)
    if not loaded then
        vim.notify("Failed to load profiles configuration\n" .. config_or_err)
        return
    end
    local config = config_or_err
    local validation_errors = jsonvalidator.validate(schema, config)
    if validation_errors then
        vim.notify("Failed to load profiles configuration\n" .. jsonvalidator.errors_to_string(validation_errors))
        return
    end
    replace_wsdir_recursive(config, ext_data.ws_dir)
    return config
end

---@param ext_data loop.ExtensionData
local function _cmake_configure(ext_data)
    local config = _load_ext_config(ext_data)
    if not config then return end
    ---@cast config CMakeConfig
    local task_list, error_msg = tasks.get_configure_tasks(config)
    if not task_list then
        vim.notify("Failed to build cmake configure tasks")
        if error_msg then
            logs.log({ "failed to build cmake configure tasks", error_msg }, vim.log.levels.ERROR)
        end
        return
    end
    local page_group = ext_data.request_page_proup("CMake configure")
    if not page_group then return end
    if page_group.have_pages() and not page_group.is_expired() then
        vim.notify("Another configure operation is already running")
        return
    end
    local function next_task()
        if #task_list == 0 then
            page_group.expire()
            return
        end
        ---@type  loop-cmake.Task
        local task = task_list[1]
        logs.log({ "running cmake configure command", vim.inspect({
            name = task.name,
            command = task.command,
            cwd = task.cwd,
            env = task.env,
        }) })
        table.remove(task_list, 1)
        local page_data = page_group.add_page({
            label = task.name,
            type = "term",
            activate = true,
            term_args = {
                name = task.name,
                command = task.command,
                cwd = task.cwd,
                env = task.env,
                on_exit_handler = function(code)
                    next_task()
                end
            }
        })
        if not page_data then
            page_group.expire()
        end
    end
    next_task()
end


---@param args string[]
---@param ext_data loop.ExtensionData
local function _do_command(args, ext_data)
    if #args == 0 then return end
    if args[1] == "setup_profiles" then
        _setup_profiles(ext_data)
        return
    end
    if args[1] == "configure" then
        _cmake_configure(ext_data)
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
            local config = _load_ext_config(ext_data)
            if not config then return {} end
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
