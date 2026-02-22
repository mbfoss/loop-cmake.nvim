--- @meta

assert(false, "should not require meta file")

---@class loop-cmake.Task : loop.Task
---@field command string[]|string|nil
---@field cwd string?
---@field env table<string,string>? # optional environment variables
---@field quickfix_matcher string|nil
