local profile_order = { "name", "build_type", "source_dir", "build_dir", "configure_args", "build_tool_args",
"quickfix_matcher" }
return {
    __order = { "$schema", "config" },
    ["$schema"] = "",
    config = {
        __order = { "cmake_path", "ctest_path" },
        cmake_path = "cmake",
        ctest_path = "ctest",
        profiles = {
            {
                __order = profile_order,
                name = "Debug",
                build_type = "Debug",
                source_dir = "${wsdir}",
                build_dir = "${wsdir}/build/Debug",
                configure_args = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
                build_tool_args = "-j8",
                quickfix_matcher = "gcc"
            },
            {
                __order = profile_order,
                name = "Release",
                build_type = "Release",
                source_dir = "${wsdir}",
                build_dir = "${wsdir}/build/Release",
                configure_args = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
                build_tool_args = "-j8",
                quickfix_matcher = "gcc"
            }
        }
    }
}
