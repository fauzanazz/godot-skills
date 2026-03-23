# Unit Testing (GUT)

GUT (Godot Unit Test) is the standard unit testing framework for Godot 4.x. This covers GUT for logic/behavior testing. For visual test harnesses (screenshot capture + visual QA), see `test-harness.md`.

## Setup

Install GUT as an addon in `addons/gut/`. Add to project:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

## CLI Execution

```bash
# Run all tests:
godot --headless -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/ -glog=1

# Run specific test file:
godot --headless -s addons/gut/gut_cmdln.gd \
    -gtest=res://tests/test_player.gd -glog=1

# Run specific test method:
godot --headless -s addons/gut/gut_cmdln.gd \
    -gtest=res://tests/test_player.gd \
    -gunit_test_name=test_jump_velocity

# JUnit XML output for CI:
godot --headless -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/ -gjunit_xml_file=res://test_results.xml

# With timeout:
timeout 120 godot --headless -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/ -glog=1 2>&1
```

## Test Structure

```gdscript
# tests/test_player.gd
extends GutTest

var player: CharacterBody2D

func before_each() -> void:
    player = CharacterBody2D.new()
    add_child_autofree(player)  # Auto-freed after each test

func after_each() -> void:
    pass  # Cleanup if needed

func test_initial_velocity_is_zero() -> void:
    assert_eq(player.velocity, Vector2.ZERO)

func test_health_decreases_on_damage() -> void:
    player.set_script(load("res://scripts/player.gd"))
    player.take_damage(10)
    assert_eq(player.health, 90)

func test_player_dies_at_zero_health() -> void:
    player.set_script(load("res://scripts/player.gd"))
    player.health = 1
    player.take_damage(1)
    assert_true(player.is_dead)
```

## Naming

- Test files: `test_*.gd` in `tests/` or `res://tests/`
- Test methods: `func test_*():`
- Test class: `extends GutTest`

## Assertions

```gdscript
assert_eq(a, b, "message")          # a == b
assert_ne(a, b)                      # a != b
assert_true(expr)                    # expr is true
assert_false(expr)                   # expr is false
assert_null(val)                     # val is null
assert_not_null(val)                 # val is not null
assert_gt(a, b)                      # a > b
assert_lt(a, b)                      # a < b
assert_between(val, low, high)       # low <= val <= high
assert_almost_eq(a, b, tolerance)    # |a-b| <= tolerance
assert_has(array, value)             # array contains value
assert_does_not_have(array, value)   # array doesn't contain value
assert_has_signal(obj, "signal_name")
assert_signal_emitted(obj, "signal_name")
assert_signal_not_emitted(obj, "signal_name")
assert_signal_emit_count(obj, "signal_name", count)
```

## Doubles and Stubs

```gdscript
# Double (mock) a class:
var doubled = double(PlayerScript).new()

# Stub a method:
stub(doubled, "get_health").to_return(100)
stub(doubled, "take_damage").to_do_nothing()

# Verify calls:
assert_called(doubled, "take_damage")
assert_call_count(doubled, "take_damage", 1)
```

## Async Tests

```gdscript
func test_timer_fires() -> void:
    var timer := Timer.new()
    timer.wait_time = 0.1
    timer.one_shot = true
    add_child_autofree(timer)
    timer.start()
    await timer.timeout
    assert_true(true, "Timer fired")

# Wait for signal with timeout:
func test_signal_with_timeout() -> void:
    watch_signals(my_node)
    my_node.start_action()
    await wait_for_signal(my_node.action_completed, 5.0)
    assert_signal_emitted(my_node, "action_completed")
```

## JUnit XML Parsing

GUT outputs standard JUnit XML when `-gjunit_xml_file` is set. Parse for CI:

```xml
<testsuites>
  <testsuite name="test_player" tests="3" failures="1" errors="0">
    <testcase name="test_initial_velocity_is_zero" classname="test_player"/>
    <testcase name="test_health_decreases_on_damage" classname="test_player">
      <failure message="Expected 90 but got 100"/>
    </testcase>
  </testsuite>
</testsuites>
```

## GUT vs gdUnit4

- **GUT** — mature, widely used, good CLI support, simpler API. Default choice.
- **gdUnit4** — more features (parameterized tests, test discovery), heavier. Use when you need advanced test patterns.
