local schema = {
    required = { "cmake_action", "cmake_profile", "cmake_target" },
    properties = {
        cmake_action = {
            type = "string",
            enum = { "configure", "build", "run", "test" }
        },
        cmake_profile = {
            type = "string"
        },
        cmake_target = {
            type = "string"
        },
        cwd = {
            type = { "string", "null" },
            description = "working directory",
        },
        env = {
            type = { "object", "null" },
            additionalProperties = { type = "string" },
            description = "Optional environment variables",
        },
        quickfix_matcher = {
            type = { "string", "null" },
        },
    },
}

return schema
