-- IMPORTANT: keep this module light for lazy loading

require('loop.extensions').register_extension({
    name = "cmake",
    module = "loop-cmake.ext",
    is_cmd_provider = true,
    is_task_provider = true,
})
