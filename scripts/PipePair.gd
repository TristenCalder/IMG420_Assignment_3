extends Node2D

@export var speed: float = -220.0
@export var score_offset_x: float = 0.0   # nudge if pair origin isn't centered

@onready var gate: Area2D      = get_node_or_null("ScoreGate") as Area2D
@onready var top_body: Node    = get_node_or_null("PipeTop")
@onready var bottom_body: Node = get_node_or_null("PipeBottom")

var _scored := false
var _bird: Node2D

func _ready() -> void:
	if is_instance_valid(top_body):    top_body.add_to_group("pipe")
	if is_instance_valid(bottom_body): bottom_body.add_to_group("pipe")

	# If a ScoreGate exists, keep it working (belt-and-suspenders)
	if gate:
		gate.monitoring = true
		gate.monitorable = true
		if not gate.body_entered.is_connected(Callable(self, "_on_gate_body_entered")):
			gate.body_entered.connect(Callable(self, "_on_gate_body_entered"))

		var cs: CollisionShape2D = gate.get_node("CollisionShape2D")
		if cs.shape == null:
			cs.shape = RectangleShape2D.new()
			(cs.shape as RectangleShape2D).size = Vector2(260, 300)
		cs.disabled = false

	# Cache the Bird for pass-by scoring (works even if ScoreGate disappears)
	_bird = get_tree().current_scene.find_child("Bird", true, false)

func _physics_process(delta: float) -> void:
	if GameState.is_dead:
		queue_free()
		return

	position.x += speed * delta
	if position.x < -300.0:
		queue_free()
		return

	# PASS-BY SCORING: once Bird’s X passes this pair's X (+ optional offset)
	if not _scored and _bird and is_instance_valid(_bird):
		if _bird.global_position.x > global_position.x + score_offset_x:
			_award_score()

func _on_gate_body_entered(body: Node2D) -> void:
	if GameState.is_dead or _scored: return
	if body is CharacterBody2D and body.name == "Bird":
		_award_score()
		# Remove the gate so it can’t re-fire
		if gate and is_instance_valid(gate):
			gate.queue_free()

func _award_score() -> void:
	_scored = true
	GameState.add_point(1)  # existing scoring API
	# Uncomment for debugging:
	# print("[SCORE] -> ", GameState.score)
