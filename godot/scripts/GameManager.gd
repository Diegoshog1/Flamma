extends Node
# GameManager: Central game state, timer, difficulty, boss spawning.

signal game_over
signal victory
signal difficulty_changed(level: int)
signal boss_spawned(boss_type: String)
signal time_updated(seconds: float)

const DIFFICULTY_INTERVAL := 60.0  # seconds between difficulty bumps
const MINI_BOSS_TIME := 300.0       # 5 minutes
const FINAL_BOSS_TIME := 600.0      # 10 minutes

var game_time := 0.0
var difficulty_level := 1
var is_running := false
var is_paused := false

var _mini_boss_spawned := false
var _final_boss_spawned := false
var _next_difficulty_threshold := DIFFICULTY_INTERVAL

func _ready() -> void:
	pass

func start_game() -> void:
	game_time = 0.0
	difficulty_level = 1
	is_running = true
	is_paused = false
	_mini_boss_spawned = false
	_final_boss_spawned = false
	_next_difficulty_threshold = DIFFICULTY_INTERVAL

func _process(delta: float) -> void:
	if not is_running or is_paused:
		return

	game_time += delta
	time_updated.emit(game_time)

	# Difficulty ramp
	if game_time >= _next_difficulty_threshold:
		difficulty_level += 1
		_next_difficulty_threshold += DIFFICULTY_INTERVAL
		difficulty_changed.emit(difficulty_level)

	# Boss triggers
	if not _mini_boss_spawned and game_time >= MINI_BOSS_TIME:
		_mini_boss_spawned = true
		boss_spawned.emit("mini_boss")

	if not _final_boss_spawned and game_time >= FINAL_BOSS_TIME:
		_final_boss_spawned = true
		boss_spawned.emit("final_boss")

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false

func trigger_game_over() -> void:
	is_running = false
	get_tree().paused = true
	game_over.emit()

func trigger_victory() -> void:
	is_running = false
	get_tree().paused = true
	victory.emit()

func get_formatted_time() -> String:
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]
