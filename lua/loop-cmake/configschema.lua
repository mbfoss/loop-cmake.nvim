return {
    ["$schema"] = "http://json-schema.org/draft-07/schema#",
    type = "object",
    required = { "cmake_path", "profiles" },
    additionalProperties = false,
    properties = {
        cmake_path = {
            type = "string",
            pattern = "^.+$"
        },
        ctest_path = {
            type = "string"
        },
        profiles = {
            type = "array",
            items = {
                type = "object",
                additionalProperties = false,
                properties = {
                    name = {
                        type = "string",
                        pattern = "^.+$"
                    },
                    build_type = {
                        type = "string",
                        enum = { "Debug", "Release", "RelWithDebInfo", "MinSizeRel" }
                    },
                    source_dir = {
                        type = "string",
                        pattern = "^.+$"
                    },
                    build_dir = {
                        type = "string",
                        pattern = "^.+$"
                    },
                    configure_args = {
                        oneOf = {
                            { type = "string" },
                            {
                                type = "array",
                                items = { type = "string" }
                            }
                        }
                    },
                    build_tool_args = {
                        oneOf = {
                            { type = "string" },
                            {
                                type = "array",
                                items = { type = "string" }
                            }
                        }
                    },
                    quickfix_matcher = {
                        type = "string",
                        description = "Matcher used to fill the quickfix list"
                    }
                },
                required = {
                    "name",
                    "build_type",
                    "source_dir",
                    "build_dir",
                    "quickfix_matcher"
                },
            }
        }
    },
}
