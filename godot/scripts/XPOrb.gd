extends Area2D
# XPOrb: Floats until the player's pickup area overlaps it, then awards XP.

@export var xp_value := 5

const ATTRACT_SPEED := 250.0

var _attracting := false
var _player: Node2D = null

@onready var body_draw: Node2D = $BodyDraw

func _ready() -> void:
	collision_layer = 4   # XP orbs on layer 4
	collision_mask = 0
	monitorable = true
	monitoring = false
	position += Vector2(randf_range(-12, 12), randf_range(-12, 12))

func _process(delta: float) -> void:
	if _attracting and _player != null and is_instance_valid(_player):
		var dir := global_position.direction_to(_player.global_position)
		global_position += dir * ATTRACT_SPEED * delta
		# Collect when close enough
		if global_position.distance_to(_player.global_position) < 20.0:
			_collect()

func start_attract(player: Node2D) -> void:
	_attracting = true
	_player = player

func _collect() -> void:
	if is_instance_valid(_player) and _player.has_method("gain_xp"):
		_player.gain_xp(xp_value)
	queue_free()
