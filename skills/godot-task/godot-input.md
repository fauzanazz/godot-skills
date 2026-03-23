# Input

## Action-Based (preferred)

```gdscript
Input.is_action_pressed("move_right")      # Held down
Input.is_action_just_pressed("jump")       # Just pressed this frame
Input.is_action_just_released("fire")      # Just released
Input.get_action_strength("accelerate")    # 0.0 to 1.0
Input.get_axis("move_left", "move_right")  # -1.0 to 1.0
Input.get_vector("left", "right", "up", "down")  # Vector2
```

Only use input actions declared in the plan's `inputs[]`. If none declared, use direct key checks.

## Direct Key/Mouse

```gdscript
Input.is_key_pressed(KEY_W)
Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
Input.get_mouse_position()
```

## Event Handling

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        jump()
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            shoot()

func _unhandled_input(event: InputEvent) -> void:
    # Called for input not consumed by UI
    pass
```

**`_input()` vs `_unhandled_input()`:** Use `_unhandled_input()` for gameplay input — it's skipped when UI Control nodes consume the event (buttons, text fields). Use `_input()` only when you need to intercept input before UI gets it (pause menu toggle, screenshot key).

## InputEvent Hierarchy

```
InputEvent
├── InputEventAction          # Synthetic action events
├── InputEventKey             # Keyboard
├── InputEventMouseButton     # Mouse clicks
├── InputEventMouseMotion     # Mouse movement
├── InputEventJoypadButton    # Gamepad buttons
├── InputEventJoypadMotion    # Gamepad sticks/triggers
├── InputEventScreenTouch     # Touch start/end
├── InputEventScreenDrag      # Touch drag
└── InputEventMIDI            # MIDI input
```

## InputMap in project.godot

```ini
[input]
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97)]
}
```

Easier to define actions programmatically in an autoload:
```gdscript
func _ready() -> void:
    if not InputMap.has_action("move_left"):
        InputMap.add_action("move_left")
        var ev := InputEventKey.new()
        ev.physical_keycode = KEY_A
        InputMap.action_add_event("move_left", ev)
```

## Simulated Input (for testing)

```gdscript
Input.action_press("move_forward")
Input.action_release("move_forward")

# Via InputEvent (more control):
var ev := InputEventAction.new()
ev.action = &"jump"
ev.pressed = true
Input.parse_input_event(ev)
```
