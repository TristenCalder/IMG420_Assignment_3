extends Node

@export var shield_scene: PackedScene
@export var shield_interval_sec: float = 6.0
var _shield_timer: Timer

@export var interval: float = 1.6
var running := false
@onready var timer: Timer = get_node_or_null("Timer")

func _ready() -> void:
	if timer == null:
		timer = Timer.new()
		timer.name = "Timer"
		add_child(timer)
	timer.autostart = false
	timer.one_shot = false
	timer.wait_time = interval
	if not timer.timeout.is_connected(Callable(self, "_spawn_pair")):
		timer.timeout.connect(Callable(self, "_spawn_pair"))
	if _shield_timer == null:
		_shield_timer = Timer.new()
		_shield_timer.wait_time = shield_interval_sec
		_shield_timer.autostart = true
		_shield_timer.one_shot = false
		add_child(_shield_timer)
		_shield_timer.timeout.connect(_spawn_shield)

func start() -> void:
	if running: return
	running = true
	_spawn_pair()
	timer.start()

func reset() -> void:
	running = false
	timer.stop()

func stop() -> void:
	reset()

func _spawn_pair() -> void:
	if not running: return
	var pair := preload("res://scenes/PipePair.tscn").instantiate()
	get_tree().current_scene.add_child(pair)
	var vp := get_viewport().get_visible_rect().size
	pair.global_position = Vector2(vp.x + 100.0, randf_range(120.0, vp.y - 120.0))

func _spawn_shield() -> void:
	if shield_scene == null:
		push_warning("[Shield] shield_scene not set in Inspector")
		return

	var s = shield_scene.instantiate()
	# spawn under the game root so it behaves like your other pickups
	get_tree().current_scene.add_child(s)

	var vp := get_viewport().get_visible_rect().size
	s.global_position = Vector2(vp.x + 40.0, randf_range(96.0, vp.y - 96.0))
	print("[Shield] spawned @ ", s.global_position)
