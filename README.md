# mise-xcode

A mise env plugin that selects an installed Xcode and exports `DEVELOPER_DIR`.
It does not download or install Xcode; it only points to what is already on disk.

## Usage

Add the plugin and configure it in your `mise.toml`:

```toml
[plugins]
xcode = "https://github.com/hisaac/mise-xcode.git"

[env._.xcode]
version = "16.4"
```

To pin to a specific release, branch, or commit:

```toml
[plugins]
xcode = "https://github.com/hisaac/mise-xcode.git#v1.0.0"
```

The `#` fragment supports tags (`#v1.0.0`), branches (`#main`), and commit SHAs.

Then load the environment:

```bash
mise env
```

## Configuration

The plugin supports these options under `[env._.xcode]`:

- `version` (string, required unless `version_file` is set): desired Xcode version, can be partial like `16` or `16.4`.
- `version_file` (string, optional): path to a file containing the desired version.
- `additional_search_paths` (string or array, optional): extra directories to scan for `Xcode*.app`.
- `debug` (bool, optional): print detected installations and selection details.

Example with a version file and extra search paths:

```toml
[env._.xcode]
version_file = ".xcode-version"
additional_search_paths = ["~/Applications", "/Volumes/SDKs"]
debug = true
```

## Project Layout

- `hooks/mise_env.lua`: selects the best matching installed Xcode and sets `DEVELOPER_DIR`.
- `hooks/mise_path.lua`: no PATH changes.
- `lib/`: core logic for version parsing, Xcode representation, and selection.
- `tests/`: LuaUnit tests and a runner at `tests/run.lua`.

## Development

Bootstrap dev dependencies (LuaUnit + Luacheck):

```bash
mise run bootstrap
```

Run unit tests:

```bash
mise run test-unit
```

Run integration tests (macOS/Linux expectations):

```bash
mise run test-integration
```
