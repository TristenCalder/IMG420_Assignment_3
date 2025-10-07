extends Node2D

@onready var spawner: Node           = $PipeSpawner
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var bird: CharacterBody2D   = $Bird

var _wired := false

func _ready() -> void:
	get_tree().paused = false
	if not has_node("HUD"):
		add_child(preload("res://scenes/HUD.tscn").instantiate())
	if not _wired:
		pause_menu.restart_requested.connect(_reset)
		GameState.game_over.connect(_on_game_over)
		GameState.game_won.connect(_on_game_won)
		_wired = true
	_reset()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		if get_tree().paused: pause_menu.close()
		else:                 pause_menu.open()

func _reset() -> void:
	get_tree().paused = false

	for n in get_tree().current_scene.get_children():
		if n and (str(n.name).begins_with("PipePair") or str(n.name).begins_with("ScoreGate")):
			n.queue_free()

	var vp := get_viewport().get_visible_rect().size
	bird.global_position = Vector2(vp.x * 0.18, vp.y * 0.5)
	bird.velocity = Vector2.ZERO
	bird.rotation = 0.0

	GameState.new_game()
	if spawner.has_method("reset"): spawner.reset()
	if spawner.has_method("start"): spawner.start()

func _on_game_over() -> void:
	if spawner.has_method("stop"): spawner.stop()
	get_tree().paused = false
	await get_tree().process_frame
	var err := get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	if err != OK:
		push_error("Failed to change to GameOver.tscn: %s" % err)

func _on_game_won() -> void:
	if spawner.has_method("stop"): spawner.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Win.tscn")
