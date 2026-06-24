extends Node
# WeaponManager: Auto-attacks nearest enemy with sword-slash projectiles.

const SlashScene := preload("res://scenes/Slash.tscn")

var attack_cooldown := 1.2
var damage := 20
var projectile_count := 1
var projectile_speed := 400.0

var _timer := 0.0
var _enemies_group := "enemies"

@onready var _player: CharacterBody2D = get_parent()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= attack_cooldown:
		_timer = 0.0
		_fire()

func _fire() -> void:
	var target := _get_nearest_enemy()
	if target == null:
		return

	var base_dir := (_player.global_position.direction_to(target.global_position))

	# Spawn projectile_count slashes, spread slightly for multishot
	for i in range(projectile_count):
		var angle_offset := 0.0
		if projectile_count > 1:
			angle_offset = deg_to_rad((i - (projectile_count - 1) / 2.0) * 20.0)
		var dir := base_dir.rotated(angle_offset)
		_spawn_slash(dir)

func _spawn_slash(direction: Vector2) -> void:
	var slash: Node2D = SlashScene.instantiate()
	slash.global_position = _player.global_position
	slash.direction = direction
	slash.speed = projectile_speed
	slash.damage = damage
	# Add to world so it isn't parented to player
	get_tree().current_scene.add_child(slash)

func _get_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group(_enemies_group)
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d := _player.global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest
