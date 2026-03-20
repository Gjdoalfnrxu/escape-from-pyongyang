extends Area2D

signal picked_up(player_id: int)

@export var loot_name: String = "Intelligence Documents"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("pickup_loot"):
		body.pickup_loot()
		picked_up.emit(body.player_id)
		queue_free()
