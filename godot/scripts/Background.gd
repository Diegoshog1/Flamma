extends Node2D
# Background: Draws a tiled beige paper grid to fill the visible arena.

const TILE_SIZE := 64
const GRID_COLOR := Color(0.82, 0.78, 0.68, 1.0)   # beige paper
const LINE_COLOR := Color(0.72, 0.68, 0.58, 0.6)   # subtle ink lines
const HALF_EXTENT := 2000  # draw area half-size

func _draw() -> void:
	# Fill background
	draw_rect(Rect2(-HALF_EXTENT, -HALF_EXTENT, HALF_EXTENT * 2, HALF_EXTENT * 2), GRID_COLOR)

	# Horizontal lines
	var y := -HALF_EXTENT
	while y <= HALF_EXTENT:
		draw_line(Vector2(-HALF_EXTENT, y), Vector2(HALF_EXTENT, y), LINE_COLOR, 1.0)
		y += TILE_SIZE

	# Vertical lines
	var x := -HALF_EXTENT
	while x <= HALF_EXTENT:
		draw_line(Vector2(x, -HALF_EXTENT), Vector2(x, HALF_EXTENT), LINE_COLOR, 1.0)
		x += TILE_SIZE
