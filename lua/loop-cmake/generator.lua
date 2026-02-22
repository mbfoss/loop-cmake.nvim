---@class CMakeProfile
---@field name string
---@field build_type '"Debug"'|'"Release"'|'"RelWithDebInfo"'|'"MinSizeRel"' # required
---@field source_dir string # required, non-empty
---@field build_dir string # required, non-empty
---@field configure_args string|string[]|nil
---@field build_tool_args string|string[]|nil
---@field quickfix_matcher string|nil


---@class CMakeConfig
---@field cmake_path string # required, non-empty
---@field ctest_path string # required, non-empty
---@field profiles CMakeProfile[] # required, at least one item

local M         = {}

local filetools = require('loop.tools.file')
local strtools  = require('loop.tools.strtools')

local json      = vim.json

-- ----------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------
local function realpath(p)
    return vim.fn.fnamemodify(vim.fn.resolve(p), ':p')
end

local function readfile(p)
    local ok, content = filetools.read_content(p)
    return ok and content or nil
end
-- ----------------------------------------------------------------------
-- Safe JSON decoder – patches CMake's "v:null" key
-- ----------------------------------------------------------------------
local function safe_json_decode(str)
    if not str or str == "" then
        return nil, "empty input"
    end
    local ok, res = pcall(json.decode, str)
    if not ok then
        return nil, "JSON decode failed: " .. tostring(res)
    end
    if res == nil then
        return nil, "decoded result is nil"
    end
    local t = type(res)
    if t ~= "table" and t ~= "string" and t ~= "number" and t ~= "boolean" then
        return nil, string.format("unexpected decoded type: %s", t)
    end
    return res, nil
end

-- ----------------------------------------------------------------------
-- Ensure CMake API query exists (MUST be called BEFORE configure)
-- ----------------------------------------------------------------------
function M.ensure_cmake_api_query(build_dir)
    local query_dir = vim.fs.joinpath(build_dir, ".cmake", "api", "v1", "query")

    local function make_marker(subpath)
        local path = vim.fs.joinpath(query_dir, subpath)
        local ok, err = filetools.make_dir(path)
        if not ok then error("Failed to create dir: " .. (err or "")) end
        local marker = vim.fs.joinpath(path, "request")
        local ok2, err2 = filetools.write_content(marker, "")
        if not ok2 then error("Failed to write marker: " .. (err2 or "")) end
    end

    -- Request codemodel (for targets)
    make_marker("codemodel-v2")

    -- Also request test info
    make_marker("test-v1")
end

-- ----------------------------------------------------------------------
-- 1. CMake File-Based API → list of *real* targets
-- ----------------------------------------------------------------------
---@param build_dir string
---@return table<string,string>|nil, string[]|nil
local function query_cmake_api_targets(build_dir)
    local reply_dir = vim.fs.joinpath(build_dir, ".cmake", "api", "v1", "reply")
    if not filetools.dir_exists(reply_dir) then
        return nil, { "Target list not available - Run configure first" }
    end

    ------------------------------------------------------------------
    -- 1. Find index-*.json
    ------------------------------------------------------------------
    local index_file
    for entry in vim.fs.dir(reply_dir) do
        if entry:match("^index%-.+%.json$") then
            index_file = vim.fs.joinpath(reply_dir, entry)
            break
        end
    end
    if not index_file then
        return nil, { "No index-*.json in reply directory" }
    end

    local idx_content = readfile(index_file)
    if not idx_content then
        return nil, { "Failed to read index file: " .. index_file }
    end

    local idx, err = safe_json_decode(idx_content)
    if not idx then
        return nil, { "Failed to parse index JSON: " .. (err or "") }
    end

    ------------------------------------------------------------------
    -- 2. Locate codemodel entry (reply or query)
    ------------------------------------------------------------------
    local codemodel_entry
    if idx.reply and idx.reply["codemodel-v2"] then
        codemodel_entry = idx.reply["codemodel-v2"]
    elseif idx.query then
        codemodel_entry = idx.query["codemodel-v2"] or idx.query["codemodel-v1"]
    end

    if not codemodel_entry or not codemodel_entry.jsonFile then
        return nil, { "No codemodel entry found in index file (checked reply and query)" }
    end

    ------------------------------------------------------------------
    -- 3. Read codemodel file – it only contains *references* to targets
    ------------------------------------------------------------------
    local codemodel_file = vim.fs.joinpath(reply_dir, codemodel_entry.jsonFile)
    local codemodel_content = readfile(codemodel_file)
    if not codemodel_content then
        return nil, { "Failed to read codemodel file: " .. codemodel_file }
    end

    local codemodel, err2 = safe_json_decode(codemodel_content)
    if not codemodel then
        return nil, { "Failed to parse codemodel JSON: " .. (err2 or "") }
    end

    ------------------------------------------------------------------
    -- 4. Walk every target reference and load the real target file
    ------------------------------------------------------------------
    local targets = {}
    local target_errors = {}

    for _, cfg in ipairs(codemodel.configurations or {}) do
        for _, tgt_ref in ipairs(cfg.targets or {}) do
            local tgt_name = tgt_ref.name
            local tgt_file = tgt_ref.jsonFile
            if not tgt_name or not tgt_file then goto continue end

            local full_tgt_path = vim.fs.joinpath(reply_dir, tgt_file)
            local tgt_content = readfile(full_tgt_path)
            if not tgt_content then
                table.insert(target_errors, " could not read target file: " .. full_tgt_path)
                goto continue
            end

            local tgt_obj, err3 = safe_json_decode(tgt_content)
            if not tgt_obj then
                table.insert(target_errors, "failed to parse target JSON: " .. full_tgt_path .. " - " .. (err3 or ""))
                goto continue
            end

            targets[tgt_name] = tgt_obj.type

            ::continue::
        end
    end

    if not next(targets) then
        return nil, { "No executable targets found in CMake API" }
    end

    return targets, target_errors
end

---@param ctest_path string
---@param build_dir string
---@return table[]|nil,string|nil
local function query_cmake_api_tests(ctest_path, build_dir)
    -- Try CTest JSON interface first (CMake ≥3.29)
    local handle = io.popen(ctest_path .. " --show-only=json-v1 --test-dir " .. vim.fn.shellescape(build_dir))
    if not handle then
        return nil, "Failed to run ctest"
    end
    local content = handle:read("*a")
    handle:close()

    if not content or content == "" then
        return nil, "CTest JSON output empty"
    end

    local data, err = safe_json_decode(content)
    if not data then
        return nil, "Failed to parse CTest JSON: " .. err
    end

    if not data.tests or not next(data.tests) then
        return nil, "No tests found in CTest JSON"
    end

    return data.tests, nil
end

-- ----------------------------------------------------------------------
-- Core task generator
-- ----------------------------------------------------------------------
---@param tasks loop.taskTemplate[][]
---@param cmake_path string
---@param ctest_path string
---@param cfg CMakeProfile
---@return boolean, string[]|nil
function M.get_profile_tasks(tasks, cmake_path, ctest_path, cfg)
    local profile_name = cfg.name
    local src_root = realpath(cfg.source_dir) or cfg.source_dir
    local build_dir = realpath(cfg.build_dir) or cfg.build_dir
    local quickfix_matcher = cfg.quickfix_matcher
    local cmake_file = vim.fs.joinpath(src_root, "CMakeLists.txt")

    if not filetools.file_exists(cmake_file) then
        return false, { "CMakeLists.txt not found (" .. cmake_file .. ")" }
    end


    local all_targets, targets_errors = query_cmake_api_targets(build_dir)
    if not all_targets then
        return false, targets_errors
    end

    -- ------------------------------------------------------------------
    -- 2. Build All
    -- ------------------------------------------------------------------
    do
        local cmd = { cmake_path, "--build", build_dir }
        if cfg.build_tool_args then
            table.insert(cmd, "--")
            vim.list_extend(cmd, strtools.cmd_to_string_array(cfg.build_tool_args))
        end
        local name = ("Build all (%s)"):format(profile_name)
        ---@type loop.taskTemplate[]
        local task = {
            name = name,
            type = "build",
            command = cmd,
            cwd = src_root,
            quickfix_matcher = quickfix_matcher,
        }
        table.insert(tasks, task)
    end

    local function build_task_name(tgt, tgt_type)
        return ("Build: %s (%s)"):format(tgt, profile_name)
    end

    -- ------------------------------------------------------------------
    -- 2½. Build specific targets (optional cfg.build_targets)
    -- ------------------------------------------------------------------
    do
        for tgt, tgt_type in pairs(all_targets) do
            local cmd = { cmake_path, "--build", build_dir, "--target", tgt }
            if cfg.build_tool_args then
                table.insert(cmd, "--")
                vim.list_extend(cmd, strtools.cmd_to_string_array(cfg.build_tool_args))
            end
            ---@type loop.taskTemplate[]
            local task = {
                name = build_task_name(tgt, tgt_type),
                type = "build",
                command = cmd,
                cwd = src_root,
                quickfix_matcher = quickfix_matcher
            }
            table.insert(tasks, task)
        end
    end
    -- ------------------------------------------------------------------
    -- 3. Run Targets
    -- ------------------------------------------------------------------
    for tgt, tgt_type in pairs(all_targets) do
        -- Only keep *real* executables (skip UTILITY, INTERFACE, etc.)
        if tgt_type == "EXECUTABLE" or tgt_type == "MACOSX_BUNDLE" then
            local name = ("Run: %s (%s)"):format(tgt, profile_name)
            local exec_path = vim.fs.joinpath(build_dir, tgt)
            local cmd = { exec_path }
            local cwd = build_dir
            ---@type loop.taskTemplate[]
            local task =
            {
                name = name,
                type = "build",
                command = cmd,
                cwd = cwd,
                depends_on = { build_task_name(tgt, tgt_type) }
            }
            table.insert(tasks, task);
        end
    end
    ----------------------------------------------------------------------
    -- 4. CTest API
    ----------------------------------------------------------------------
    if ctest_path and ctest_path ~= "" then
        local tests, err = query_cmake_api_tests(ctest_path, build_dir)
        if not tests then
            return false, { err }
        end
        for _, t in ipairs(tests) do
            if t.name and t.command then
                local name = ("CTest: %s (%s)"):format(t.name, profile_name)
                ---@type loop.taskTemplate[]
                local task = {
                    name    = name,
                    type    = "build",
                    command = t.command,
                    cwd     = build_dir
                }
                table.insert(tasks, task)
            end
        end
        do
            local name = ("CTest all (%s)"):format(profile_name)
            -- Add a meta-task to run all tests
            ---@type loop.taskTemplate[]
            local task = {
                name    = name,
                type    = "build",
                command = { "ctest", "--output-on-failure" },
                cwd     = build_dir
            }
            table.insert(tasks, task)
        end
        do
            local name = ("CTest rerun failed (%s)"):format(profile_name)
            -- Add a meta-task to run failed tests
            ---@type loop.taskTemplate[]
            local task = {
                name    = name,
                type    = "build",
                command = { "ctest", "--rerun-failed", "--output-on-failure" },
                cwd     = build_dir
            }
            table.insert(tasks, task)
        end
    end
    return true
end

return M
