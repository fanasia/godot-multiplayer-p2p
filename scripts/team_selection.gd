extends Control

@onready var team_blue_button: Button = $VBoxContainer/HBoxContainer/TeamBlueButton
@onready var team_red_button: Button = $VBoxContainer/HBoxContainer/TeamRedButton
@onready var team_blue_label: Label = $VBoxContainer/HBoxContainer2/TeamBlueLabel
@onready var team_red_label: Label = $VBoxContainer/HBoxContainer2/TeamRedLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("team_selection_ui")
	# In case we already have assignment data (e.g. re-entering scene), refresh immediately
	_on_team_assignments_updated(NetworkManager.team_assignments)

func _on_team_blue_button_pressed() -> void:
	# send message request team("Blue") to peer ID 1 (host)
	NetworkManager.request_team.rpc_id(1, "Blue")

func _on_team_red_button_pressed() -> void:
	NetworkManager.request_team.rpc_id(1, "Red")

func _on_team_assignments_updated(assignments: Dictionary) -> void:
	var team_blue_owner = -1
	var team_red_owner = -1

	for peer_id in assignments:
		if assignments[peer_id] == "Blue":
			team_blue_owner = peer_id
		elif assignments[peer_id] == "Red":
			team_red_owner = peer_id

	team_blue_label.text = "Taken by Player %d" % team_blue_owner if team_blue_owner != -1 else ""
	team_red_label.text = "Taken by Player %d" % team_red_owner if team_red_owner != -1 else ""

	team_blue_button.disabled = team_blue_owner != -1 and team_blue_owner != multiplayer.get_unique_id()
	team_red_button.disabled = team_red_owner != -1 and team_red_owner != multiplayer.get_unique_id()

	if team_blue_owner != -1 and team_red_owner != -1:
		status_label.text = "Both teams selected! Ready to start."
	else:
		status_label.text = "Waiting for both players to pick a team..."
