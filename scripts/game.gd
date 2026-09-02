extends Node2D

@onready var waiting_overlay: Control = $GameUI/WaitingOverlay
@onready var your_team_label: Label = $GameUI/HBoxContainer/TeamLabel
@onready var turn_label: Label = $GameUI/HBoxContainer/TurnLabel
@onready var phase_label: Label = $GameUI/HBoxContainer/PhaseLabel
@onready var turn_indicator_label: Label = $GameUI/HBoxContainer/TurnIndicatorLabel
@onready var next_phase_button: Button = $GameUI/HBoxContainer/NextPhaseButton
@onready var camera: Camera2D = $Camera2D

const GRID_SIZE := 8
const TILE_SIZE := 64

func _ready() -> void:
	add_to_group("game_ui")
	_show_my_team()
	_center_camera_on_map()
	NetworkManager.request_game_state.rpc_id(1)

func _show_my_team() -> void:
	var my_id = multiplayer.get_unique_id()
	var my_team = NetworkManager.team_assignments.get(my_id, "Unknown")
	your_team_label.text = "You are: Team " + my_team

func _center_camera_on_map() -> void:
	var map_pixel_size = GRID_SIZE * TILE_SIZE
	camera.position = Vector2(map_pixel_size / 2.0, map_pixel_size / 2.0)
	
func _on_next_phase_button_pressed() -> void:
	NetworkManager.request_next_phase.rpc_id(1)
	
func _on_turn_state_updated(turn_number: int, turn_team: String, phase_index: int) -> void:
	var phase_name = NetworkManager.PHASES[phase_index]
	turn_label.text = "Turn %d" % turn_number
	phase_label.text = "Phase: " + phase_name

	var my_id = multiplayer.get_unique_id()
	var my_team = NetworkManager.team_assignments.get(my_id, "")
	var is_my_turn = (my_team == turn_team)

	turn_indicator_label.text = "Team %s's Turn" % turn_team
	
	waiting_overlay.visible = not is_my_turn
	next_phase_button.disabled = not is_my_turn	
