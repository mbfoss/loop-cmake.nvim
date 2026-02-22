local M = {}

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

---@param config CMakeConfig
---@param ingore_configured boolean
---@return loop-cmake.Task[]|nil,string[]|nil
local function _get_configure_tasks(config, ingore_configured)
	_init_cmake_api(config)
	local profiles = config.profiles or {}
	if #profiles == 0 then
		return nil, {"No configured CMake profiles"}
	end
	local tasks = {}
	for _, prof in ipairs(profiles) do
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
				---@type loop.taskTemplate[]
				local task = {
					name = profile_name,
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
---@return loop.taskTemplate[]
function M.get_tasks(config)
	local params_ok, params_errors = _check_params(config)
	if not params_ok then
		if params_errors then vim.notify(table.concat(params_errors, '\n')) end
		return {}
	end
	_init_cmake_api(config)

	local tasks = {}
	local all_errors = {}
	for _, prof in ipairs(config.profiles or {}) do
		local _, prof_errs = generator.get_profile_tasks(tasks, config.cmake_path, config.ctest_path, prof)
		if prof_errs and #prof_errs > 0 then
			vim.list_extend(all_errors,
				strtools.indent_errors(prof_errs, "While loading profile '" .. (prof.name or '(unkown)') .. "'"))
		end
	end

	if all_errors and #all_errors > 0 then
		vim.notify(table.concat(all_errors, '\n'))
	end
	local templates = {}
	for _, task in ipairs(tasks) do
		table.insert(templates, {
			name = task.name,
			task = task
		})
	end
	return templates
end

---@param config CMakeConfig
---@return loop-cmake.Task[]|nil,string|nil
function M.get_configure_tasks(config)
	local tasks, errors = _get_configure_tasks(config, false)
	if not tasks then
		if errors then
			return nil, table.concat(errors, '\n')
		end
		return nil, "Unknown error"
	end
	return tasks, nil
end

return M
