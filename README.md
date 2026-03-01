# loop-cmake.nvim

CMake extension for [loop.nvim](https://github.com/mbfoss/loop.nvim). Integrates CMake configuration, building, testing, and execution into the Loop task system. Uses the CMake File-Based API to discover targets and tests.

## Requirements

- **Neovim** ≥ 0.10  
- **CMake** ≥ 3.29 (File-Based API support)  
- **loop.nvim**
- **loop-build.nvim**

## Features

- **Profiles** — Configure multiple build profiles (Debug, Release, etc.) with source dir, build dir, configure args, and build tool args.
- **Configure** — Generate build files for each profile via `:Loop cmake configure`.
- **Task templates** — Import Configure, Build All, Build Target, Run, CTest, and CTest Rerun tasks from the **CMake** category.
- **Quickfix** — Optional `quickfix_matcher` per profile to parse compiler output into the quickfix list.

## Installation

**lazy.nvim**

```lua
{
    "mbfoss/loop-cmake.nvim",
    dependencies = { "mbfoss/loop.nvim", "mbfoss/loop-build.nvim" },
}
```

## Quick Start

1. Install loop.nvim, loop-build.nvim and loop-cmake.nvim.
2. Open a loop workspace in a CMake project (`:Loop workspace create` to create and `:Loop workspace open` to open).
3. Run `:Loop cmake setup` — Opens the profiles editor. Adjust `cmake_path`, `ctest_path`, and profiles as needed
4. Run `:Loop cmake configure` — Generates build files for each profile.
5. Add tasks — Use `:Loop task configure` and add tasks from the **CMake** template category
6. Run tasks — `:Loop task run` (or `:Loop task run Build`).

## Commands

| Command | Description |
|--------|-------------|
| `:Loop cmake setup` | Open the CMake profiles editor. |
| `:Loop cmake configure` | Run CMake configure for each profile (generates build files). |

## Configuration

Profiles are stored in `.nvimloop/ext.cmake.profiles.json`. Edit via `:Loop cmake setup` or manually.

### Top-level options

| Option | Type | Description | Required |
|-------|------|-------------|----------|
| `cmake_path` | string | Path to `cmake` executable | ✓ |
| `ctest_path` | string | Path to `ctest` executable | |
| `profiles` | array | Build profiles | ✓ |

### Profile options

| Option | Type | Description | Required |
|--------|------|-------------|----------|
| `name` | string | Profile display name | ✓ |
| `build_type` | string | `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel` | ✓ |
| `source_dir` | string | Source root (supports `${wsdir}`) | ✓ |
| `build_dir` | string | Build directory | ✓ |
| `configure_args` | string \| array | CMake configure arguments | |
| `build_tool_args` | string \| array | Build tool args (e.g. `-j8` for make) | |
| `quickfix_matcher` | string | Quickfix matcher (e.g. `gcc`) |  |

## Default template

```json
{
  "cmake_path": "cmake",
  "ctest_path": "ctest",
  "profiles": [
    {
      "name": "Debug",
      "build_type": "Debug",
      "source_dir": "${wsdir}",
      "build_dir": "${wsdir}/build/Debug",
      "configure_args": ["-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"],
      "build_tool_args": "-j8",
      "quickfix_matcher": "gcc"
    },
    {
      "name": "Release",
      "build_type": "Release",
      "source_dir": "${wsdir}",
      "build_dir": "${wsdir}/build/Release",
      "configure_args": ["-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"],
      "build_tool_args": "-j8",
      "quickfix_matcher": "gcc"
    }
  ]
}
```

## Generated task types

| Type | Description |
|------|-------------|
| **Build All** | Build all targets in a profile |
| **Build Target** | Build a single target |
| **Run** | Run a built executable |
| **CTest** | Run tests (all or individual) |
| **CTest Rerun** | Rerun only failed tests |

## License

MIT
