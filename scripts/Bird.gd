extends CharacterBody2D

@export var gravity: float        = 1400.0
@export var flap_strength: float  = -420.0
@export var dash_impulse: Vector2 = Vector2(260, 0)
@export var dive_force: float     = 1000.0
@export var max_fall: float       = 900.0
@export var death_floor_ratio: float = 0.85

@onready var sprite: Sprite2D = $GDBirdSprite
@onready var gfx: AnimatedSprite2D = (get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D)

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask  = 1 << 1
	set_safe_margin(4.0)
	if is_instance_valid(gfx):
		gfx.animation = "Flap"; gfx.stop(); gfx.frame = 1; gfx.speed_scale = 1.0
		gfx.animation_finished.connect(_on_gfx_finished)
	if not is_instance_valid(sprite):
		push_error("GDBirdSprite (FlappySprite) missing under Bird scene.")
	else:
		var cb := Callable(self, "_on_bird_bobbing_peak")
		if not sprite.is_connected("bobbing_peak", cb): sprite.connect("bobbing_peak", cb)
		if (typeof(GameState) != TYPE_NIL) and GameState.has_signal("game_event"):
			if not GameState.is_connected("game_event", sprite.on_game_event):
				GameState.game_event.connect(sprite.on_game_event)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	if Input.is_action_just_pressed("flap"):
		velocity.y = flap_strength
		_play_flap_once()
	if Input.is_action_just_pressed("dash"):
		velocity += dash_impulse
	if Input.is_action_pressed("dive"):
		velocity.y = min(velocity.y + dive_force * delta, max_fall)

	move_and_slide()

	var floor_y := get_viewport().get_visible_rect().size.y * death_floor_ratio
	if global_position.y >= floor_y and not GameState.is_dead:
		GameState.lose()
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		global_position.y = floor_y
		return

	var hit_pipe := false
	var hit_pair: Node = null
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var body := col.get_collider()
		if body and body.is_in_group("pipe"):
			hit_pipe = true
			hit_pair = body.get_parent()
			break
	if hit_pipe:
		if "shield_time" in GameState and GameState.shield_time > 0.0:
			if "use_shield" in GameState: GameState.use_shield()
			if is_instance_valid(hit_pair): hit_pair.queue_free()
			velocity = Vector2(0, -220)
			await _blink_brief()
		elif not GameState.is_dead:
			GameState.lose()
			set_physics_process(false)
			collision_layer = 0
			collision_mask = 0

func _play_flap_once() -> void:
	if not is_instance_valid(gfx): return
	gfx.animation = "Flap"; gfx.frame = 0; gfx.play()

func _on_gfx_finished() -> void:
	if is_instance_valid(gfx) and gfx.animation == "Flap": gfx.stop(); gfx.frame = 1

func _blink_brief() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.25, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.08)
	await tw.finished

func _on_bird_bobbing_peak(_sp: Node, _pos: Vector2) -> void:
	if not is_instance_valid(sprite): return
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 0.8, 0.2), 0.05)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.10)
