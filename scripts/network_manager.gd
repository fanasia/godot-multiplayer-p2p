extends Node

const PORT := 7777
const MAX_PLAYERS := 1  # 1 extra peer besides the host = 2 players total

var peer: ENetMultiplayerPeer

var team_assignments: Dictionary = {}

const TEAM_SELECTION_PATH := "res://scenes/team_selection.tscn"
const LOADING_SCENE_PATH := "res://scenes/loading.tscn"
const GAME_SCENE_PATH := "res://scenes/game.tscn"

const PHASES := ["Movement", "Detection", "Identification", "Attack"]

var current_turn_number: int = 1
var current_turn_team: String = "Blue"
var current_phase_index: int = 0

# create a server
func host_game() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to host: ", error)
		return
		

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	print("Hosting on port ", PORT)

# connect to that IP on the same port
func join_game(ip_address: String) -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		print("Failed to join: ", error)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
func _on_peer_connected(id: int) -> void:
	print("A player connected with id: ", id)
	# Host tells everyone (including itself) to move to team selection
	change_scene_everyone.rpc(TEAM_SELECTION_PATH)

func _on_connected_to_server() -> void:
	print("Successfully connected to host!")

func _on_connection_failed() -> void:
	print("Could not connect to host.")

@rpc("authority", "call_local", "reliable")
func change_scene_everyone(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

# # Called by a CLIENT (or host) button press, asking the host for a team
@rpc("any_peer", "call_local", "reliable")
func request_team(team: String) -> void:
	# only host process this logic
	if not multiplayer.is_server():
		return

	var requester_id = multiplayer.get_remote_sender_id()
	if requester_id == 0:
		requester_id = multiplayer.get_unique_id()

	# Check if team is already taken by someone else
	for existing_id in team_assignments:
		if team_assignments[existing_id] == team and existing_id != requester_id:
			print("Team already taken, request denied.")
			return

	team_assignments[requester_id] = team

	confirm_team_assignment.rpc(team_assignments)
	
	_check_if_ready_to_start()
	
@rpc("authority", "call_local", "reliable")
func confirm_team_assignment(new_assignments: Dictionary) -> void:
	team_assignments = new_assignments

	get_tree().call_group("team_selection_ui", "_on_team_assignments_updated", team_assignments)

func _check_if_ready_to_start() -> void:
	# We need exactly 2 players, each with a DIFFERENT team assigned
	if team_assignments.size() == 2:
		var teams_picked = team_assignments.values()
		if teams_picked[0] != teams_picked[1]:
			change_scene_everyone.rpc(LOADING_SCENE_PATH)
			
@rpc("any_peer", "call_local", "reliable")
func request_next_phase() -> void:
	if not multiplayer.is_server():
		return

	var requester_id = multiplayer.get_remote_sender_id()
	if requester_id == 0:
		requester_id = multiplayer.get_unique_id()

	# check current turn
	var requester_team = team_assignments.get(requester_id, "")
	if requester_team != current_turn_team:
		print("Not your turn, request denied.")
		return

	# update current phase
	current_phase_index += 1
	if current_phase_index >= PHASES.size():
		current_phase_index = 0
		current_turn_number += 1 #changing turn
		current_turn_team = "Red" if current_turn_team == "Blue" else "Red"

	_broadcast_turn_state()
	
func _broadcast_turn_state() -> void:
	update_turn_state.rpc(current_turn_number, current_turn_team, current_phase_index)

@rpc("authority", "call_local", "reliable")
func update_turn_state(turn_number: int, turn_team: String, phase_index: int) -> void:
	current_turn_number = turn_number
	current_turn_team = turn_team
	current_phase_index = phase_index
	get_tree().call_group("game_ui", "_on_turn_state_updated", turn_number, turn_team, phase_index)

@rpc("any_peer", "call_local", "reliable")
func request_game_state() -> void:
	if not multiplayer.is_server():
		return

	var requester_id = multiplayer.get_remote_sender_id()
	if requester_id == 0:
		requester_id = multiplayer.get_unique_id()

	update_turn_state.rpc_id(requester_id, current_turn_number, current_turn_team, current_phase_index)
	
