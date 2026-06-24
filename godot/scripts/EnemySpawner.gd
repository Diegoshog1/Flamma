extends Node
# EnemySpawner: Continuously spawns enemies around the player, scaling with difficulty.

const EnemyScene := preload("res://scenes/Enemy.tscn")

const BASE_SPAWN_INTERVAL := 2.0
const SPAWN_RADIUS := 550.0   # distance from player to spawn
const MAX_ENEMIES := 120

var _timer := 0.0
var _spawn_interval := BASE_SPAWN_INTERVAL
var _difficulty := 1
var _player: Node2D = null
var _hp_multiplier := 1.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	# Connect difficulty signal from GameManager
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.difficulty_changed.connect(_on_difficulty_changed)
		gm.boss_spawned.connect(_on_boss_spawned)

func _process(delta: float) -> void:
	if _player == null:
		return
	_timer += delta
	if _timer >= _spawn_interval:
		_timer = 0.0
		_try_spawn()

func _try_spawn() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
		return
	_spawn_enemy(false)

func _spawn_enemy(is_boss: bool) -> void:
	if _player == null:
		return
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * SPAWN_RADIUS
	var spawn_pos := _player.global_position + offset

	var enemy: CharacterBody2D = EnemyScene.instantiate()
	if is_boss:
		enemy.max_health = int(200 * _hp_multiplier * _difficulty)
		enemy.move_speed = 55.0
		enemy.contact_damage = 25
		enemy.xp_value = 100
		enemy.is_boss = true
		enemy.get_node("BodyDraw").scale = Vector2(3.0, 3.0)
	else:
		enemy.max_health = int(30 * _hp_multiplier)
		enemy.move_speed = 75.0 + _difficulty * 5.0

	enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(enemy)

func _on_difficulty_changed(level: int) -> void:
	_difficulty = level
	_hp_multiplier = 1.0 + (level - 1) * 0.25
	# Reduce spawn interval (min 0.4s)
	_spawn_interval = max(0.4, BASE_SPAWN_INTERVAL - (level - 1) * 0.2)

func _on_boss_spawned(boss_type: String) -> void:
	# Spawn extra-tough boss enemies
	var count := 1 if boss_type == "mini_boss" else 3
	for i in range(count):
		_spawn_enemy(true)
