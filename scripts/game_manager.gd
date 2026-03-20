extends Node

signal game_over(winner_id: int)
signal loot_collected(player_id: int)
signal extraction_reached(player_id: int)

enum State { LOBBY, IN_GAME, EXTRACTED, GAME_OVER }

var state: State = State.LOBBY
var alive_players: Dictionary = {}
var extracted_players: Array = []
var loot_items: Array = []

@onready var network: Node = $"/root/NetworkManager"


func _ready() -> void:
	network.game_started.connect(_on_game_started)
	network.player_left.connect(_on_player_left)


func spawn_player(player_id: int, spawn_pos: Vector2) -> void:
	var player_scene := preload("res://scenes/player.tscn")
	var player := player_scene.instantiate()
	player.player_id = player_id
	player.global_position = spawn_pos
	player.name = "Player_%d" % player_id
	get_tree().current_scene.get_node("Players").add_child(player)
	alive_players[player_id] = player


func _on_game_started() -> void:
	state = State.IN_GAME
	var spawn_points: Array = get_tree().get_nodes_in_group("spawn_points")
	var i := 0
	for pid in network.players:
		var pos := Vector2(200, 200) if spawn_points.is_empty() else spawn_points[i % spawn_points.size()].global_position
		spawn_player(pid, pos)
		i += 1


func on_player_reached_extraction(player_id: int) -> void:
	if player_id in alive_players:
		var player := alive_players[player_id]
		extracted_players.append({
			"id": player_id,
			"had_loot": player.carrying_loot,
		})
		player.queue_free()
		alive_players.erase(player_id)
		extraction_reached.emit(player_id)
		_check_game_over()


func _on_player_left(id: int) -> void:
	if id in alive_players:
		alive_players[id].queue_free()
		alive_players.erase(id)
		_check_game_over()


func _check_game_over() -> void:
	if alive_players.is_empty():
		state = State.GAME_OVER
		var winner := extracted_players[0]["id"] if not extracted_players.is_empty() else -1
		game_over.emit(winner)
