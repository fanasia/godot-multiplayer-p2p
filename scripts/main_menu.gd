extends Control

@onready var menu_page: VBoxContainer = $MenuPage
@onready var host_page: VBoxContainer = $HostPage
@onready var join_page: VBoxContainer = $JoinPage

@onready var ip_label: Label = $HostPage/IPLabel
@onready var ip_input: LineEdit = $JoinPage/IPInput


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_page(menu_page)

func _on_start_game_button_pressed() -> void:
	NetworkManager.host_game()
	var my_ip = NetworkManager.get_local_ip()
	ip_label.text = "Your IP is: " + my_ip
	_show_page(host_page)

func _on_join_game_button_pressed() -> void:
	_show_page(join_page)

func _on_join_button_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		return
	NetworkManager.join_game(ip)

func _show_page(page_to_show: Control) -> void:
	menu_page.visible = false
	host_page.visible = false
	join_page.visible = false
	page_to_show.visible = true
