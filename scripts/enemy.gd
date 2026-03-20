extends CharacterBody2D

const SPEED := 80.0
const AGGRO_RANGE := 400.0
const FIRE_RANGE := 250.0
const FIRE_RATE := 2.0
const DAMAGE := 15
const MAX_HEALTH := 60

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

var health: int = MAX_HEALTH
var target: CharacterBody2D = null
var can_fire: bool = true

@onready var fire_timer: Timer = $FireTimer
@onready var detection_area: Area2D = $DetectionArea
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	fire_timer.wait_time = FIRE_RATE
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered_detection)
	detection_area.body_exited.connect(_on_body_exited_detection)


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > AGGRO_RANGE:
		target = null
		return
	if dist > FIRE_RANGE:
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * SPEED
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		look_at(target.global_position)
		if can_fire:
			_fire()


func _fire() -> void:
	can_fire = false
	fire_timer.start()
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.rotation = global_rotation
	bullet.shooter_id = -1  # enemy id
	get_tree().current_scene.add_child(bullet)


func take_damage(amount: int) -> void:
	health -= amount
	health_bar.value = health
	if health <= 0:
		queue_free()


func _on_body_entered_detection(body: Node) -> void:
	if target == null and body is CharacterBody2D and body.has_method("take_damage"):
		target = body


func _on_body_exited_detection(body: Node) -> void:
	if body == target:
		target = null


func _on_fire_timer_timeout() -> void:
	can_fire = true
