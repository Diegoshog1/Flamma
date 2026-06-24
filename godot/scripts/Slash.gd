extends Area2D
# Slash: Sword projectile that travels in a direction, damages enemies, then disappears.

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 20
var _lifetime := 0.6

@onready var body_draw: Node2D = $BodyDraw

func _ready() -> void:
	rotation = direction.angle()
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # hits enemies on layer 2
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
