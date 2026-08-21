# Workstation Setup

Shared workstation setup for the Godot Skills source repo and the game repos it publishes.

## .NET 9 SDK

Godot C# projects need .NET 9 or newer.

### macOS

```bash
brew install dotnet@9
```

### Linux (Ubuntu/Debian)

```bash
wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh
/tmp/dotnet-install.sh --channel 9.0 --install-dir "$HOME/.dotnet"
```

Add to `~/.bashrc`:

```bash
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
```

## Godot 4 (.NET edition)

The **.NET edition** is required. The standard build cannot run C# scripts.

### macOS

```bash
brew install --cask godot-mono
sudo tee /usr/local/bin/godot >/dev/null <<'EOF'
#!/usr/bin/env bash
exec /Applications/Godot_mono.app/Contents/MacOS/Godot "$@"
EOF
sudo chmod +x /usr/local/bin/godot
```

Use a wrapper, **not** `ln -s` to the binary inside the bundle. The .NET build finds `GodotSharp/` in `Godot_mono.app/Contents/Resources/` by resolving from its own executable path; invoked through a bare symlink it loses the bundle and `--headless` hangs forever with no error. (Symlinking `Contents/Resources/GodotSharp` next to the symlink also works, but the wrapper needs no duplication.)

### Linux

```bash
VERSION=$(curl -s https://api.github.com/repos/godotengine/godot/releases/latest \
  | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/-stable//')
cd /tmp
wget "https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_mono_linux_x86_64.zip"
unzip "Godot_v${VERSION}-stable_mono_linux_x86_64.zip"
sudo mv "Godot_v${VERSION}-stable_mono_linux_x86_64" /usr/local/bin/godot
```

On Linux, `GodotSharp/` **must** live next to the `godot` binary — Godot resolves it relative to itself.

### Verify

```bash
dotnet --version           # 9.0.x or newer
godot --version            # 4.x.x.stable.mono
godot --headless --quit    # may print harmless RID leak warnings
```

If `godot --headless --quit` hangs or reports assembly errors, `GodotSharp/` isn't resolvable: on Linux it isn't next to the binary, on macOS you symlinked into the bundle instead of using a wrapper.

## System Packages

```bash
sudo apt-get install vulkan-tools xvfb ffmpeg imagemagick    # Linux
brew install coreutils ffmpeg imagemagick                    # macOS
```

- `vulkan-tools` — `vulkaninfo` for GPU validation
- `xvfb` — virtual X11 display for headless capture on Linux
- `ffmpeg` — MP4 encoding of proof videos and sprite frame extraction
- `imagemagick` — image resize, flip, crop for sprite pipelines
- `coreutils` — `timeout` on macOS (as `gtimeout`; alias it or use `gtimeout` in the commands)

## Verify Rendering

```bash
# Linux
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json vulkaninfo --summary 2>&1 | grep deviceName
xvfb-run -a godot --headless --quit

# macOS — Metal, no Vulkan/xvfb. Run outside a project: inside one without a main
# scene, Godot pops a modal error dialog and hangs, ignoring --quit-after.
(cd "$(mktemp -d)" && godot --rendering-method forward_plus --quit-after 2 2>&1 | head -2)
```

Video capture needs a hardware GPU driver: Vulkan on Linux/Windows, Metal on macOS (the banner reads `Metal 4.0 - Forward+ - Using Device #0: Apple ...`). A software rasterizer (`llvmpipe`/`lavapipe`) still produces stills.

## Python

Requires Python 3.10+.

```bash
pip install -r asset-gen/tools/requirements.txt
```

In a published game repo the same requirements file ships with the skill — under `.claude/skills/asset-gen/tools/`, `.agents/skills/asset-gen/tools/`, or `.opencode/skills/asset-gen/tools/` depending on the host agent.

## API Keys

Set in the environment:

- `GOOGLE_API_KEY` — [Google AI Studio](https://aistudio.google.com/), Gemini image generation
- `XAI_API_KEY` — [xAI Grok](https://console.x.ai/home), image and video generation
- `TRIPO3D_API_KEY` — [Tripo3D](https://platform.tripo3d.ai/), image-to-3D conversion
