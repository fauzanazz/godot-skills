# Export

## CLI Commands

```bash
# Release build:
godot --headless --export-release "Linux/X11" ./build/game.x86_64

# Debug build:
godot --headless --export-debug "Linux/X11" ./build/game_debug.x86_64

# Pack only (PCK file, no executable):
godot --headless --export-pack "Linux/X11" ./build/game.pck
```

The preset name (e.g., `"Linux/X11"`) must match exactly what's in `export_presets.cfg`.

## Prerequisites

1. **Export templates installed** — version must match editor version exactly. Templates go in:
   - Linux: `~/.local/share/godot/export_templates/{version}/`
   - macOS: `~/Library/Application Support/Godot/export_templates/{version}/`
   - Windows: `%APPDATA%\Godot\export_templates\{version}\`

2. **`.godot/` folder must exist** — run `godot --headless --import --quit-after 2` first. Without the import step, exports fail on missing resources.

3. **`export_presets.cfg`** — must exist in project root. Created by editor or manually.

## export_presets.cfg

```ini
[preset.0]
name="Linux/X11"
platform="Linux/X11"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="./build/game.x86_64"

[preset.0.options]
binary_format/embed_pck=true
```

Common presets:

| Platform | Preset name | Output extension |
|---|---|---|
| Linux | `"Linux/X11"` | `.x86_64` |
| Windows | `"Windows Desktop"` | `.exe` |
| macOS | `"macOS"` | `.app` or `.dmg` |
| Web | `"Web"` | `.html` |
| Android | `"Android"` | `.apk` |

## CI Export Pattern

```bash
#!/bin/bash
set -euo pipefail

# Import assets first (creates .godot/ and .import files)
timeout 120 godot --headless --import --quit-after 2

# Export
timeout 300 godot --headless --export-release "Linux/X11" ./build/game.x86_64

# Verify output exists
if [ ! -f ./build/game.x86_64 ]; then
    echo "Export failed: output not found"
    exit 1
fi
echo "Export successful: $(ls -lh ./build/game.x86_64)"
```

## Common Export Errors

| Error | Cause | Fix |
|---|---|---|
| `No export template found` | Templates not installed or version mismatch | Install matching templates |
| `Preset not found` | Preset name doesn't match `export_presets.cfg` | Check exact preset name |
| `No loader found for resource` | Assets not imported | Run `--import --quit-after 2` first |
| `PCK embed failed` | Output path not writable | Check directory permissions |
