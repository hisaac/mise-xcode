# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds the core Lua modules: `Version.lua`, `Xcode.lua`, and `utils.lua` (plugin logic and version handling).
- `hooks/` contains mise plugin hooks (`mise_env.lua`, `mise_path.lua`).
- `tests/` includes LuaUnit-based tests plus fixtures in `tests/test-data/`.
- `scripts/` contains task entrypoints used by `mise` (unit and integration test runners).
- Root config files: `mise.toml`, `stylua.toml`, `hk.pkl`.

## Build, Test, and Development Commands
- `mise run bootstrap` installs development tooling (hk, luarocks deps).
- `mise run lint` or `hk check --all` runs linters and formatting checks.
- `mise run format` or `hk fix --all` auto-fixes lint/format issues.
- `mise run test` runs unit + integration tests.
- `scripts/test-unit` runs all LuaUnit tests directly.
- `scripts/test-integration` links the plugin and validates env behavior on macOS/Linux.

## Coding Style & Naming Conventions
- Lua formatting is enforced by `stylua` (`stylua.toml`): tabs, width 4, line width 120.
- Prefer small, single-purpose functions and keep module APIs in `lib/`.
- Filenames use `UpperCamelCase.lua` for modules, `test_*.lua` for tests.

## Testing Guidelines
- Tests use LuaUnit; see `tests/README.md` for usage.
- Keep OS-dependent behavior behind guards (`utils.check_os()`), and test macOS-only paths separately.
- Naming: `tests/test_<module>.lua` with `Test<Module>:test<Behavior>()` functions.

## Commit & Pull Request Guidelines
- Commit history favors short, descriptive subjects (often lower-case, no strict prefixing). Keep messages concise and focused.
- PRs should include: a summary of changes, test results (commands run), and platform notes (macOS vs Linux), especially for hook behavior.
- If behavior changes, update or add tests under `tests/`.

## Security & Configuration Tips
- The plugin reads local Xcode installations; avoid hardcoding paths outside `/Applications` unless required.
- For debugging, use `MISE_DEBUG=1` when running `mise` commands (e.g., `MISE_DEBUG=1 mise run test`).
