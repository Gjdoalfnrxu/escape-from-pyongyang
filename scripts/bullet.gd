extends Area2D

const SPEED := 900.0
const DAMAGE := 25
const LIFETIME := 2.0

var shooter_id: int = 0
var velocity_vec: Vector2 = Vector2.ZERO


func _ready() -> void:
	velocity_vec = Vector2.RIGHT.rotated(rotation) * SPEED
	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	global_position += velocity_vec * delta


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		if body.player_id != shooter_id:
			body.take_damage(DAMAGE)
	queue_free()
