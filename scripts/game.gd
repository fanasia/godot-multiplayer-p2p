extends Node2D

@onready var your_team_label: Label = $GameUI/TeamLabel
@onready var camera: Camera2D = $Camera2D

const GRID_SIZE := 8
const TILE_SIZE := 64

func _ready() -> void:
	_show_my_team()
	_center_camera_on_map()

func _show_my_team() -> void:
	var my_id = multiplayer.get_unique_id()
	var my_team = NetworkManager.team_assignments.get(my_id, "Unknown")
	your_team_label.text = "You are: Team " + my_team

func _center_camera_on_map() -> void:
	var map_pixel_size = GRID_SIZE * TILE_SIZE
	camera.position = Vector2(map_pixel_size / 2.0, map_pixel_size / 2.0)
