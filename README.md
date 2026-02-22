<p align="center">
  <strong>CMake task provider for loop.nvim</strong>
</p>

<p align="center">
  <a href="https://neovim.io/">
    <img src="https://img.shields.io/badge/Neovim-0.10+-blueviolet.svg?style=flat-square&logo=neovim" alt="Neovim 0.10+">
  </a>
  <a href="https://github.com/mbfoss/loop.nvim/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="MIT License">
  </a>
</p>

---

> [!WARNING]
> **Work in Progress**: This plugin is in early development and not ready for public release yet.

## Overview

**loop-cmake** is a task provider extension for [loop.nvim](https://github.com/mbfoss/loop.nvim) that automates CMake workflows directly from Neovim. It seamlessly integrates CMake configuration, building, testing, and execution into a unified task system.

## Requirements

- **Neovim** ≥ 0.10
- **CMake** ≥ 3.29 (for CMake File-Based API support)
- **loop.nvim** plugin

## Features

**How to use**
1 - Run `:Loop task configure cmake` to setup profiles, a default configuration is provided, adjust as needed and safe.
2 - Run `:Loop task add cmake` and import the Configure task(s).
3 - Run the configure tasks via `Loop task run`
4 - Run `:Loop task add cmake` again add all cmake/ctest targets should be available for import as tasks.

**Generated task templates**
- **Configure**: Generate build files for each profile
- **Build All**: Build all targets in a profile
- **Build Target**: Build individual targets
- **Run**: Execute built executables
- **CTest**: Run individual tests or all tests
- **CTest Rerun**: Rerun only failed tests

## Installation

Using `lazy.nvim`:

```lua
{
  "mbfoss/loop-cmake.nvim",
  dependencies = { "mbfoss/loop.nvim" },
}
```

### Configuration Options

| Option | Type | Description | Required |
|--------|------|-------------|----------|
| `cmake_path` | string | Path to cmake executable | ✓ |
| `ctest_path` | string | Path to ctest executable | |
| `profiles` | array | Array of build profiles | ✓ |

### Profile Options

| Option | Type | Description | Required |
|--------|------|-------------|----------|
| `name` | string | Profile display name | ✓ |
| `build_type` | string | CMake build type: `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel` | ✓ |
| `source_dir` | string | Path to source root (supports `${wsdir}`) | ✓ |
| `build_dir` | string | Path to build directory | ✓ |
| `configure_args` | string\|array | CMake configure arguments | |
| `build_tool_args` | string\|array | Build tool arguments (e.g., `-j8` for make) | |
| `quickfix_matcher` | string | [loop.nvim](https://github.com/mbfoss/loop.nvim) Quickfix error matcher | |

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.