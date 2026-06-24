extends CharacterBody2D
# Enemy: Moves toward player, deals contact damage, drops XP on death.

const XPOrbScene := preload("res://scenes/XPOrb.tscn")

@export var move_speed := 80.0
@export var max_health := 30
@export var contact_damage := 10
@export var xp_value := 5
@export var is_boss := false

var health := 0
var _player: Node2D = null

@onready var body_draw: Node2D = $BodyDraw
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	collision_layer = 2   # enemies on layer 2
	collision_mask = 1    # collide with world (layer 1)
	# Find player reference
	_player = get_tree().get_first_node_in_group("player")
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = max_health
		# Only show health bar for bosses or when damaged
		health_bar.visible = is_boss

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dir := global_position.direction_to(_player.global_position)
	velocity = dir * move_speed
	move_and_slide()

	# Flip sprite
	if dir.x != 0:
		body_draw.scale.x = sign(dir.x)

func take_damage(amount: int) -> void:
	health -= amount
	if health_bar:
		health_bar.value = health
		health_bar.visible = true
	# Flash red
	body_draw.modulate = Color(1.0, 0.3, 0.3)
	var t := get_tree().create_tween()
	t.tween_property(body_draw, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		_die()

func _die() -> void:
	_drop_xp()
	queue_free()

func _drop_xp() -> void:
	var orb: Node2D = XPOrbScene.instantiate()
	orb.global_position = global_position
	orb.xp_value = xp_value
	get_tree().current_scene.add_child(orb)
