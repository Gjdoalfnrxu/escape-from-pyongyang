extends Control

@onready var host_btn: Button = $VBox/HostBtn
@onready var join_btn: Button = $VBox/JoinBtn
@onready var ip_field: LineEdit = $VBox/IPField
@onready var port_field: LineEdit = $VBox/PortField
@onready var status_label: Label = $VBox/StatusLabel
@onready var start_btn: Button = $VBox/StartBtn
@onready var player_list: VBoxContainer = $VBox/PlayerList

@onready var solo_btn: Button = $VBox/SoloBtn
@onready var network: Node = $"/root/NetworkManager"


func _ready() -> void:
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	start_btn.pressed.connect(_on_start_pressed)
	solo_btn.pressed.connect(_on_solo_pressed)
	network.player_joined.connect(_refresh_player_list)
	network.player_left.connect(_refresh_player_list)
	network.game_started.connect(_on_game_started)
	start_btn.hide()
	ip_field.placeholder_text = "Server IP"
	port_field.placeholder_text = "Port (default 4433)"
	port_field.text = "4433"


func _on_host_pressed() -> void:
	var port := int(port_field.text) if port_field.text.is_valid_int() else 4433
	var err: Error = network.host(port)
	if err == OK:
		status_label.text = "Hosting on port %d — share your IP with friends" % port
		host_btn.disabled = true
		join_btn.disabled = true
		start_btn.show()
	else:
		status_label.text = "Failed to host: %s" % error_string(err)


func _on_join_pressed() -> void:
	var ip := ip_field.text.strip_edges()
	if ip.is_empty():
		status_label.text = "Enter a server IP"
		return
	var port := int(port_field.text) if port_field.text.is_valid_int() else 4433
	var err: Error = network.join(ip, port)
	if err == OK:
		status_label.text = "Connecting to %s:%d..." % [ip, port]
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		status_label.text = "Failed to connect: %s" % error_string(err)


func _on_start_pressed() -> void:
	if not network.is_host():
		return
	network.start_game.rpc()


func _on_solo_pressed() -> void:
	# Offline solo mode: use an OfflineMultiplayerPeer so RPCs work without a server
	var offline := OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = offline
	network.players[1] = {"name": "Player_1", "ready": true}
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _on_game_started() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _refresh_player_list(_id: int = 0) -> void:
	for child in player_list.get_children():
		child.queue_free()
	for pid in network.players:
		var label := Label.new()
		label.text = network.players[pid].get("name", "Player_%d" % pid)
		player_list.add_child(label)
