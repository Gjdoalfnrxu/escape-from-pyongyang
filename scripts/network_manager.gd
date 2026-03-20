extends Node

signal player_joined(id: int)
signal player_left(id: int)
signal game_started()

const DEFAULT_PORT := 4433
const MAX_PLAYERS := 8

var players: Dictionary = {}  # id -> player data


func host(port: int = DEFAULT_PORT) -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_register_self()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Hosting on port %d" % port)
	return OK


func join(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_client("ws://%s:%d" % [ip, port])
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	print("Connecting to %s:%d" % [ip, port])
	return OK


func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	players.clear()


func is_host() -> bool:
	return multiplayer.is_server()


func _register_self() -> void:
	var id := multiplayer.get_unique_id()
	players[id] = {"name": "Player_%d" % id, "ready": false}


func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)
	player_joined.emit(id)
	if is_host():
		_send_player_list.rpc_id(id, players)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)
	players.erase(id)
	player_left.emit(id)


func _on_connected_to_server() -> void:
	_register_self()
	var id := multiplayer.get_unique_id()
	_register_player.rpc_id(1, id, players[id])


func _on_connection_failed() -> void:
	push_error("Connection failed")


@rpc("any_peer", "reliable")
func _register_player(id: int, data: Dictionary) -> void:
	if not is_host():
		return
	players[id] = data
	_broadcast_player_joined.rpc(id, data)


@rpc("authority", "reliable")
func _broadcast_player_joined(id: int, data: Dictionary) -> void:
	players[id] = data
	player_joined.emit(id)


@rpc("authority", "reliable")
func _send_player_list(player_list: Dictionary) -> void:
	players = player_list


@rpc("authority", "reliable")
func start_game() -> void:
	game_started.emit()
