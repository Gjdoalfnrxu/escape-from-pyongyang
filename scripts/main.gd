extends Node2D

const DEFAULT_PORT = 4433
const DEFAULT_IP = "127.0.0.1"

var peer: WebSocketMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func host_game(port: int = DEFAULT_PORT) -> void:
	peer = WebSocketMultiplayerPeer.new()
	var err = peer.create_server(port)
	if err != OK:
		push_error("Failed to create server: %s" % error_string(err))
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port %d" % port)


func join_game(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> void:
	peer = WebSocketMultiplayerPeer.new()
	var err = peer.create_client("ws://%s:%d" % [ip, port])
	if err != OK:
		push_error("Failed to connect: %s" % error_string(err))
		return
	multiplayer.multiplayer_peer = peer
	print("Connecting to %s:%d" % [ip, port])


func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)


func _on_connected_to_server() -> void:
	print("Connected to server. My ID: %d" % multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	push_error("Connection failed")


@rpc("any_peer", "reliable")
func sync_player_state(player_id: int, position: Vector2, health: int) -> void:
	pass
