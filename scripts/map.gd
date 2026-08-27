extends Node2D

const GRID_SIZE := 8
const TILE_SIZE := 64  # pixels per tile

func _draw() -> void:
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile_rect := Rect2(
				Vector2(col * TILE_SIZE, row * TILE_SIZE),
				Vector2(TILE_SIZE, TILE_SIZE)
			)
			var tile_color = Color(0.3, 0.3, 0.3) if (row + col) % 2 == 0 else Color(0.4, 0.4, 0.4)
			draw_rect(tile_rect, tile_color, true)
			draw_rect(tile_rect, Color(0, 0, 0), false, 1.0)  # thin border outline
