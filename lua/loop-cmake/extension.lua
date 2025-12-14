local M = {}

require('loop.task.taskdef')
local generator = require('loop-cmake.generator')
local strtools = require('loop.tools.strtools')
local filetools = require('loop.tools.file')

local function _realpath(p)
    return vim.fn.fnamemodify(vim.fn.resolve(p), ':p')
end

---@param cfg CMakeConfig
---@eturn boolean,string[]
local function _check_params(cfg)
    local errors = {}
    if vim.fn.executable(cfg.cmake_path) == 0 then
        table.insert(errors, "cmake_path not executable: '" .. (cfg.cmake_path or "") .. "'")
    end
    if cfg.ctest_path and cfg.ctest_path ~= "" and vim.fn.executable(cfg.ctest_path) == 0 then
        table.insert(errors, "ctest_path not executable: '" .. cfg.ctest_path .. "'")
    end
    for idx, prof in ipairs(cfg.profiles or {}) do
        if not prof.name or prof.name == "" then
            table.insert(errors, "profile " .. tostring(idx) .. " name is required")
        end

        if not prof.build_type or prof.build_type == "" then
            table.insert(errors, "In profile: " .. prof.name .. ", build_type is required")
        end

        if not prof.source_dir or prof.source_dir == "" then
            table.insert(errors, "In profile: " .. prof.name .. ", source_dir is required")
        end

        if not prof.build_dir or prof.build_dir == "" then
            table.insert(errors, "In profile: " .. prof.name .. ", build_dir is required")
        end
    end
    return #errors == 0, errors
end

---@param config CMakeConfig
local function _init_cmake_api(config)
    for _, prof in ipairs(config.profiles or {}) do
        local build_dir = _realpath(prof.build_dir) or prof.build_dir
        generator.ensure_cmake_api_query(build_dir)
    end
end

function M.get_name()
    return "cmake"
end

function M.get_config_schema()
    return require('loop-cmake.configschema')
end

function M.get_config_template()
    return require('loop-cmake.configtemplate')
end

---@return fun(path: string, attrs: string[]) : string[]
function M.get_config_order_handler()
    return function(_, _)
        return { "$schema", "name", "config", "cmake_path", "ctest_path",
            "build_type", "source_dir", "build_dir", "configure_args", "build_tool_args", "quickfix_matcher" }
    end
end

---@param config CMakeConfig
---@param ingore_configured boolean
---@return loop.Task[]|nil,string[]|nil
local function _get_configure_tasks(config, ingore_configured)
    _init_cmake_api(config)
    local tasks = {}
    for _, prof in ipairs(config.profiles or {}) do
        local build_type = prof.build_type

        local profile_name = prof.name
        local src_root = _realpath(prof.source_dir) or prof.source_dir
        local build_dir = _realpath(prof.build_dir) or prof.build_dir
        local cmakecache_path = vim.fs.joinpath(build_dir, "CMakeCache.txt")
        if not (ingore_configured and filetools.file_exists(cmakecache_path)) then
            do
                local cmd = { config.cmake_path }
                vim.list_extend(cmd, strtools.cmd_to_string_array(prof.configure_args))
                vim.list_extend(cmd, { "-B", build_dir, "-S", src_root, "-DCMAKE_BUILD_TYPE=" .. build_type })
                ---@type loop.Task
                local task = {
                    name = "[CMake " .. profile_name .. "] Configure",
                    type = "build",
                    command = cmd,
                    cwd = src_root
                }
                table.insert(tasks, task)
            end
        end
    end

    return tasks
end

-- ----------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------
---@param config CMakeConfig
---@return loop.Task[]|nil,string[]|nil
function M.get_tasks(config)
    local params_ok, params_errors = _check_params(config)
    if not params_ok then
        return nil, strtools.indent_errors(params_errors, "Invalid cmake config")
    end
    _init_cmake_api(config)
    local tasks, configure_tasks_errs = _get_configure_tasks(config, false)
    if not tasks then
        return nil, configure_tasks_errs
    end
    if #tasks > 1 then
        ---@type loop.Task
        local task = {
            name = "Configure All",
            type = "composite",
            depends_on = {}
        }
        for _, t in ipairs(tasks) do
            table.insert(task.depends_on, t.name)
        end
        table.insert(tasks, 1, task)
    end

    local all_errors = {}
    for _, prof in ipairs(config.profiles or {}) do
        local _, prof_errs = generator.get_profile_tasks(tasks, config.cmake_path, config.ctest_path, prof)
        if prof_errs and #prof_errs > 0 then
            vim.list_extend(all_errors,
                strtools.indent_errors(prof_errs, "While loading profile '" .. (prof.name or '(unkown)') .. "'"))
        end
    end

    return tasks, #all_errors > 0 and all_errors or nil
end

return M
