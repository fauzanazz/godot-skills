# UI (Control Nodes)

## Control Hierarchy

All UI nodes extend `Control`. Key types:

```
Control
├── Container           # Auto-layouts children
│   ├── HBoxContainer   # Horizontal row
│   ├── VBoxContainer   # Vertical column
│   ├── GridContainer   # Grid (columns property)
│   ├── MarginContainer # Adds margins around child
│   ├── CenterContainer # Centers child
│   ├── PanelContainer  # Background panel + child
│   └── ScrollContainer # Scrollable area
├── Label               # Text display
├── RichTextLabel       # BBCode-formatted text
├── Button              # Clickable
├── TextureButton       # Image-based button
├── LineEdit            # Single-line text input
├── TextEdit            # Multi-line text input
├── TextureRect         # Image display
├── ProgressBar         # Value bar
├── HSlider / VSlider   # Slider input
├── SpinBox             # Numeric input
├── OptionButton        # Dropdown
├── CheckBox / CheckButton
├── TabContainer        # Tabbed pages
└── Panel               # Background rect
```

## Anchors & Margins

Anchors define where a Control is positioned relative to its parent (0.0 = left/top, 1.0 = right/bottom).

```gdscript
# Full-screen overlay:
control.anchor_left = 0.0
control.anchor_top = 0.0
control.anchor_right = 1.0
control.anchor_bottom = 1.0

# Bottom-right corner:
control.anchor_left = 1.0
control.anchor_top = 1.0
control.anchor_right = 1.0
control.anchor_bottom = 1.0
control.offset_left = -200
control.offset_top = -100

# Preset shortcuts:
control.set_anchors_preset(Control.PRESET_FULL_RECT)
control.set_anchors_preset(Control.PRESET_CENTER)
control.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
```

## Container Sizing

- `size_flags_horizontal` / `size_flags_vertical` control how children fill space
- `SIZE_EXPAND_FILL` = take available space proportionally
- `SIZE_SHRINK_CENTER` = shrink to min size, center in allocated space
- `custom_minimum_size` = minimum dimensions

```gdscript
label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
label.custom_minimum_size = Vector2(100, 0)
```

## Themes

```gdscript
# Load theme resource:
var theme := load("res://ui_theme.tres") as Theme
control.theme = theme

# Override per-node:
button.add_theme_color_override("font_color", Color.WHITE)
button.add_theme_font_size_override("font_size", 24)
label.add_theme_stylebox_override("normal", StyleBoxFlat.new())

# StyleBoxFlat for backgrounds:
var style := StyleBoxFlat.new()
style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
style.corner_radius_top_left = 8
style.corner_radius_top_right = 8
style.corner_radius_bottom_left = 8
style.corner_radius_bottom_right = 8
style.content_margin_left = 16
style.content_margin_top = 8
panel.add_theme_stylebox_override("panel", style)
```

## CanvasLayer for HUD

HUD must render above the game world regardless of camera position:

```gdscript
var hud_layer := CanvasLayer.new()
hud_layer.layer = 10  # Above game (default layer = 1)
root.add_child(hud_layer)

var health_bar := ProgressBar.new()
hud_layer.add_child(health_bar)
```

## Focus & Input

- `focus_mode = FOCUS_ALL` to receive keyboard/gamepad input
- `focus_neighbor_*` for custom navigation order
- `grab_focus()` to programmatically focus a control

```gdscript
func _ready() -> void:
    $StartButton.grab_focus()  # First focused control
    $StartButton.pressed.connect(_on_start)

# Consume input to prevent gameplay while menu is open:
func _input(event: InputEvent) -> void:
    if visible:
        get_viewport().set_input_as_handled()
```

## Gotchas

- **Invisible Controls consume mouse events** — a `Control` with `mouse_filter = MOUSE_FILTER_STOP` (default) blocks clicks even when transparent or zero-size. Set `mouse_filter = MOUSE_FILTER_IGNORE` on overlay/container nodes that shouldn't intercept input.
- **Control vs Node2D** — never mix in the same branch. Controls use anchor/offset layout; Node2D uses pixel position. Put UI in a CanvasLayer, game in the scene tree.
- **`_gui_input()` vs `_input()`** — for Control-specific input handling (clicks on this control), use `_gui_input()`. `_input()` receives all events globally.
