extends CharacterBody2D
# Player: Frog ronin — movement, health, XP, level-up.

signal health_changed(current: int, maximum: int)
signal xp_changed(current: int, needed: int)
signal leveled_up(level: int)
signal died

const BASE_SPEED := 200.0
const BASE_MAX_HP := 100
const BASE_PICKUP_RADIUS := 80.0

var move_speed := BASE_SPEED
var max_health := BASE_MAX_HP
var health := BASE_MAX_HP
var pickup_radius := BASE_PICKUP_RADIUS
var regen_per_second := 0.0

var xp := 0
var level := 1
var xp_to_next := 20  # grows each level

var _regen_accum := 0.0
var _invincible_timer := 0.0
const INVINCIBLE_DURATION := 0.5  # brief i-frames after hit

@onready var weapon_manager: Node = $WeaponManager
@onready var body_draw: Node2D = $BodyDraw
@onready var pickup_area: Area2D = $PickupArea

func _ready() -> void:
	collision_layer = 1   # player on layer 1
	collision_mask = 2    # player detects enemies (layer 2)
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_to_next)
	_update_pickup_shape()
	# Pickup area detects XP orbs (layer 4)
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 4
	pickup_area.monitoring = true

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_regen(delta)
	_handle_invincibility(delta)

func _handle_movement(delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	velocity = dir * move_speed
	move_and_slide()

	# Flip sprite based on horizontal movement
	if dir.x != 0:
		body_draw.scale.x = sign(dir.x)

func _handle_regen(delta: float) -> void:
	if regen_per_second <= 0.0 or health >= max_health:
		return
	_regen_accum += regen_per_second * delta
	if _regen_accum >= 1.0:
		var heal_amount := int(_regen_accum)
		_regen_accum -= heal_amount
		take_damage(-heal_amount)  # negative = heal

func _handle_invincibility(delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		body_draw.modulate.a = 0.5 if fmod(Engine.get_process_frames(), 4) < 2 else 1.0
	else:
		body_draw.modulate.a = 1.0

func take_damage(amount: int) -> void:
	if amount > 0 and _invincible_timer > 0.0:
		return  # i-frames active
	health = clamp(health - amount, 0, max_health)
	health_changed.emit(health, max_health)
	if amount > 0:
		_invincible_timer = INVINCIBLE_DURATION
	if health <= 0:
		died.emit()

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()
	xp_changed.emit(xp, xp_to_next)

func _level_up() -> void:
	level += 1
	xp_to_next = int(xp_to_next * 1.4)
	leveled_up.emit(level)

func _update_pickup_shape() -> void:
	var shape := pickup_area.get_node("CollisionShape2D")
	if shape and shape.shape is CircleShape2D:
		shape.shape.radius = pickup_radius
