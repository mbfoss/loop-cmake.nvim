return {
    cmake_path = "cmake",
    ctest_path = "ctest",
    profiles = {
        {
            name = "Debug",
            build_type = "Debug",
            source_dir = "${wsdir}",
            build_dir = "${wsdir}/build/Debug",
            configure_args = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
            build_tool_args = "-j8",
            quickfix_matcher = "gcc"
        },
        {
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
