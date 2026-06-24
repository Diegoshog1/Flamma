extends Node2D
# World: Root scene. Wires all managers together, handles contact damage loop.

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node = $EnemySpawner
@onready var ui_manager: CanvasLayer = $UIManager
@onready var upgrade_manager: Node = $UpgradeManager
@onready var background: Node2D = $Background

var _contact_damage_timer := 0.0
const CONTACT_DAMAGE_INTERVAL := 0.5  # hurt player every 0.5s per touching enemy

func _ready() -> void:
	# Give player its group tag
	player.add_to_group("player")

	# Wire pickup area — XP orbs are Area2Ds, so use area_entered
	player.get_node("PickupArea").area_entered.connect(_on_pickup_area_entered)

	# Connect player death
	player.died.connect(_on_player_died)

	# Init UI
	ui_manager.init(player, upgrade_manager)

	# Connect final boss death tracking
	var gm: Node = get_node("/root/GameManager")
	gm.boss_spawned.connect(_on_boss_spawned)
	gm.start_game()

	# Contact damage: check overlapping enemies every tick
	set_process(true)

func _process(delta: float) -> void:
	_handle_contact_damage(delta)

func _handle_contact_damage(delta: float) -> void:
	_contact_damage_timer += delta
	if _contact_damage_timer < CONTACT_DAMAGE_INTERVAL:
		return
	_contact_damage_timer = 0.0

	# Check all enemies for overlap with player
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := player.global_position.distance_to(enemy.global_position)
		# Player collision radius ~14, enemy ~14
		if dist < 28:
			player.take_damage(enemy.contact_damage)

func _on_pickup_area_entered(area: Area2D) -> void:
	# XP orbs are Area2Ds; attract them when player is close
	if area.get_parent() is Node2D and area.get_parent().has_method("start_attract"):
		area.get_parent().start_attract(player)

func _on_player_died() -> void:
	get_node("/root/GameManager").trigger_game_over()

func _on_boss_spawned(boss_type: String) -> void:
	if boss_type == "final_boss":
		# Track all boss enemies; victory when all die
		await get_tree().process_frame
		_track_final_bosses()

func _track_final_bosses() -> void:
	# Find any enemy with is_boss=true and xp_value==100 (our boss marker)
	var bosses := get_tree().get_nodes_in_group("enemies").filter(
		func(e): return is_instance_valid(e) and e.get("is_boss") == true
	)
	if bosses.is_empty():
		get_node("/root/GameManager").trigger_victory()
		return

	var killed := {"count": 0, "total": bosses.size()}
	for boss in bosses:
		boss.tree_exited.connect(func():
			killed["count"] += 1
			if killed["count"] >= killed["total"]:
				get_node("/root/GameManager").trigger_victory()
		)
