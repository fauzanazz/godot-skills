# State Machine

## Node-Based Hierarchical FSM

```gdscript
# Base state — each state is a child Node of the state machine
class_name State
extends Node

signal finished(next_state: StringName)

func enter() -> void:
    pass

func exit() -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass

func update(_delta: float) -> void:
    pass
```

## State Machine Manager

```gdscript
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary[StringName, State] = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.finished.connect(_on_state_finished)
    if initial_state:
        current_state = initial_state
        current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
    current_state.handle_input(event)

func _process(delta: float) -> void:
    current_state.update(delta)

func _on_state_finished(next_state_name: StringName) -> void:
    var next: State = states.get(next_state_name)
    if not next:
        push_error("State not found: " + str(next_state_name))
        return
    current_state.exit()
    current_state = next
    current_state.enter()
```

## State Stack (push/pop for temporary states)

For interruptible states (attack, stagger, cutscene) that return to the previous state:

```gdscript
var states_stack: Array[State] = []

func push_state(state_name: StringName) -> void:
    if current_state:
        states_stack.push_front(current_state)
        current_state.exit()
    current_state = states[state_name]
    current_state.enter()

func pop_state() -> void:
    current_state.exit()
    current_state = states_stack.pop_front()
    current_state.enter()
```

## Enum-Based Simple FSM

For small state sets (3-5 states) where a full node hierarchy is overkill:

```gdscript
enum State { IDLE, RUN, JUMP, ATTACK }
var state: State = State.IDLE

func _physics_process(delta: float) -> void:
    match state:
        State.IDLE:
            _process_idle(delta)
        State.RUN:
            _process_run(delta)
        State.JUMP:
            _process_jump(delta)
        State.ATTACK:
            _process_attack(delta)

func _change_state(new_state: State) -> void:
    state = new_state
```

## When to Use What

- **Enum FSM** — 3-5 states, simple transitions, single script. Fast to write, hard to scale.
- **Node-based FSM** — 6+ states, complex enter/exit logic, shared transitions. Scales well, each state is its own script.
- **AnimationTree state machine** — when state transitions map 1:1 to animation changes and you don't need custom logic per state. Don't use when states have complex gameplay behavior beyond animation.
