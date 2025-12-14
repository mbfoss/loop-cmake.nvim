---@alias loop.TaskType "build"|"run"|"debug"|"vimcmd"|"composite"

---@class loop.Task
---@field name string # non-empty task name (supports ${VAR} templates)
---@field type loop.TaskType # task category
---@field command string[]|string|nil
---@field cwd string?
---@field env table<string,string>? # optional environment variables
---@field quickfix_matcher string|nil
---@field depends_on string[]? # optional list of dependent task names
---@field debugger string|nil
---@field debugger_config table<string,any>|nil
---@field debug_request "launch"|"attach"|nil
---@field debug_args table<string,any>|nil

---@class loop.taskTemplate
---@field name string
---@field task loop.Task