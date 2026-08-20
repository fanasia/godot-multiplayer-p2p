extends Node

const PORT := 7777
const MAX_PLAYERS := 1  # 1 extra peer besides the host = 2 players total

var peer: ENetMultiplayerPeer

var team_assignments: Dictionary = {}

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
	change_scene_everyone.rpc("res://scenes/team_selection.tscn")

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
	
@rpc("authority", "call_local", "reliable")
func confirm_team_assignment(new_assignments: Dictionary) -> void:
	team_assignments = new_assignments

	get_tree().call_group("team_selection_ui", "_on_team_assignments_updated", team_assignments)
