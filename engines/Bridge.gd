extends Node
## TCP command bridge — ships with the godot-skills runtime; wire contract in godot.md.
## Enable with: godot --path . -- --bridge [port]   (default 9080)

const DEFAULT_PORT := 9080
const PEER_TIMEOUT_MS := 5000

var _server: TCPServer = null
var _pending: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # stay reachable while the tree is paused
	var args := OS.get_cmdline_user_args()
	var idx := args.find("--bridge")
	if idx < 0:
		return  # gate: bind only when asked
	var port := DEFAULT_PORT
	if idx + 1 < args.size() and args[idx + 1].is_valid_int():
		port = args[idx + 1].to_int()
	_server = TCPServer.new()
	var err := _server.listen(port, "127.0.0.1")
	if err != OK:
		if err == ERR_ALREADY_IN_USE:
			push_error("Bridge: port %d already in use, bridge off" % port)
		else:
			push_error("Bridge: listen failed: %s" % error_string(err))
		_server = null

func _process(_delta: float) -> void:
	if _server == null:
		return
	if _server.is_connection_available():
		var peer := _server.take_connection()
		peer.set_no_delay(true)
		_pending.append({"peer": peer, "since": Time.get_ticks_msec(), "buffer": ""})
	for i in range(_pending.size() - 1, -1, -1):
		var p: Dictionary = _pending[i]
		p.peer.poll()
		if p.peer.get_status() == StreamPeerTCP.STATUS_NONE:
			# client closed before we finished — drop, nothing to read or reply to
			_pending.remove_at(i)
			continue
		var avail: int = p.peer.get_available_bytes()
		if avail > 0:
			p.buffer += p.peer.get_utf8_string(avail)  # never ask for more than avail
		var nl: int = p.buffer.find("\n")
		var stale: bool = Time.get_ticks_msec() - p.since > PEER_TIMEOUT_MS
		if nl < 0 and not stale:
			continue
		if nl >= 0:
			var reply := _handle(p.buffer.substr(0, nl)) + "\n"
			p.peer.put_data(reply.to_utf8_buffer())
		p.peer.disconnect_from_host()
		_pending.remove_at(i)

func _handle(line: String) -> String:
	if not line.begins_with("{"):
		return _err("malformed request")
	var data = JSON.parse_string(line)
	# nothing off the wire is trusted: a JSON value can be any type, and a typed
	# assignment from the wrong one aborts _handle, so the client gets no reply at all
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("cmd")) != TYPE_STRING:
		return _err("malformed request")
	var cmd: String = data.cmd
	match cmd:
		"ping":
			return _reply({"frame": Engine.get_process_frames()})
		"action":
			var action_name = data.get("name")
			if typeof(action_name) != TYPE_STRING or (action_name as String).is_empty():
				return _err("action needs a non-empty string name")
			var raw_hold = data.get("hold", 0.1)
			if typeof(raw_hold) != TYPE_INT and typeof(raw_hold) != TYPE_FLOAT:
				return _err("hold must be a number")
			# ponytail: 10s ceiling so a fat-fingered hold can't pin an action all session
			var hold: float = clampf(float(raw_hold), 0.0, 10.0)
			var name_str: String = action_name
			Input.action_press(name_str)
			get_tree().create_timer(hold).timeout.connect(func() -> void:
				Input.action_release(name_str))  # timed release is not optional
			return _reply({})
		"state":
			return _reply({"state": _snapshot()})
		_:
			return _err("unknown cmd %s" % cmd)

func _reply(fields: Dictionary) -> String:
	var out := {"ok": true}
	out.merge(fields)
	return JSON.stringify(out)  # never hand-build: an echoed quote breaks the reply

func _err(reason: String) -> String:
	return JSON.stringify({"ok": false, "error": reason})

func _snapshot() -> Dictionary:
	# generic facts every project has; a game adds its own keys here
	var scene := get_tree().current_scene
	return {
		"frame": Engine.get_process_frames(),
		"scene": scene.scene_file_path if scene else "",
		"nodes": get_tree().get_node_count(),
		"uptime_ms": Time.get_ticks_msec(),
		"fps": Engine.get_frames_per_second(),
		"paused": get_tree().paused,
		"debugger_active": EngineDebugger.is_active(),
		"perf": {
			"t_process_us": Performance.get_monitor(Performance.TIME_PROCESS),
			"t_physics_us": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
			"t_nav_us": Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"phys2d_objects": Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
			"phys2d_pairs": Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS),
			"phys2d_islands": Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT),
		},
	}
