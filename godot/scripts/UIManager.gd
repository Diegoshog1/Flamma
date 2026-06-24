extends CanvasLayer
# UIManager: HUD, upgrade screen, game over / victory overlays.

@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var xp_bar: ProgressBar = $HUD/XPBar
@onready var timer_label: Label = $HUD/TimerLabel
@onready var level_label: Label = $HUD/LevelLabel

@onready var upgrade_panel: Control = $UpgradePanel
@onready var upgrade_card_container: HBoxContainer = $UpgradePanel/VBox/Cards

@onready var game_over_panel: Control = $GameOverPanel
@onready var victory_panel: Control = $VictoryPanel

var _player: Node = null
var _upgrade_manager: Node = null

func _ready() -> void:
	upgrade_panel.visible = false
	game_over_panel.visible = false
	victory_panel.visible = false

func init(player: Node, upgrade_manager: Node) -> void:
	_player = player
	_upgrade_manager = upgrade_manager

	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_player_died)

	var gm: Node = get_node("/root/GameManager")
	gm.time_updated.connect(_on_time_updated)
	gm.game_over.connect(_show_game_over)
	gm.victory.connect(_show_victory)

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func _on_xp_changed(current: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current

func _on_leveled_up(new_level: int) -> void:
	level_label.text = "LV %d" % new_level
	_show_upgrade_choices()

func _on_time_updated(seconds: float) -> void:
	var gm: Node = get_node("/root/GameManager")
	timer_label.text = gm.get_formatted_time()

func _show_upgrade_choices() -> void:
	# Clear previous cards
	for child in upgrade_card_container.get_children():
		child.queue_free()

	var options: Array = _upgrade_manager.get_random_upgrades(3)
	for upgrade in options:
		var btn := _make_card(upgrade)
		upgrade_card_container.add_child(btn)

	upgrade_panel.visible = true
	get_node("/root/GameManager").pause_game()

func _make_card(upgrade: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 140)
	btn.text = "%s\n\n%s" % [upgrade["name"], upgrade["description"]]
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1, 0.8, 0.2))
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(upgrade["icon_color"].r * 0.4, upgrade["icon_color"].g * 0.4, upgrade["icon_color"].b * 0.4, 0.95)
	style.border_color = upgrade["icon_color"]
	style.set_border_width_all(3)
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	btn.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate()
	hover_style.bg_color = Color(upgrade["icon_color"].r * 0.6, upgrade["icon_color"].g * 0.6, upgrade["icon_color"].b * 0.6, 0.95)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(func(): _on_upgrade_selected(upgrade))
	return btn

func _on_upgrade_selected(upgrade: Dictionary) -> void:
	_upgrade_manager.apply_upgrade(upgrade, _player)
	upgrade_panel.visible = false
	get_node("/root/GameManager").resume_game()

func _on_player_died() -> void:
	_show_game_over()

func _show_game_over() -> void:
	game_over_panel.visible = true
	game_over_panel.get_node("VBox/RestartBtn").pressed.connect(_restart)

func _show_victory() -> void:
	victory_panel.visible = true
	victory_panel.get_node("VBox/RestartBtn").pressed.connect(_restart)

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
