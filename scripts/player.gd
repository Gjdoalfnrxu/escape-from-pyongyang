extends CharacterBody2D

const SPEED := 220.0
const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@export var player_id: int = 1
@export var max_health: int = 100
@export var fire_rate: float = 0.15  # seconds between shots

var health: int = max_health
var can_fire: bool = true
var is_local_player: bool = false
var carrying_loot: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var gun_pivot: Node2D = $GunPivot
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var fire_timer: Timer = $FireTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _ready() -> void:
	is_local_player = player_id == multiplayer.get_unique_id()
	health_bar.max_value = max_health
	health_bar.value = health
	if not is_local_player:
		set_process_input(false)


func _physics_process(_delta: float) -> void:
	if not is_local_player:
		return
	_handle_movement()
	_aim_at_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_fire:
			_fire()


func _handle_movement() -> void:
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	velocity = dir * SPEED
	move_and_slide()
	if velocity != Vector2.ZERO:
		_sync_position.rpc(global_position, global_rotation)


func _aim_at_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	gun_pivot.look_at(mouse_pos)


func _fire() -> void:
	can_fire = false
	fire_timer.start(fire_rate)
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = gun_pivot.global_rotation
	bullet.shooter_id = player_id
	get_tree().current_scene.add_child(bullet)
	_sync_fire.rpc(muzzle.global_position, gun_pivot.global_rotation)


func take_damage(amount: int) -> void:
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()


func die() -> void:
	_on_player_died.rpc()


func pickup_loot() -> void:
	carrying_loot = true
	modulate = Color(1.0, 0.85, 0.1)


@rpc("authority", "reliable")
func _on_player_died() -> void:
	queue_free()


@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector2, rot: float) -> void:
	if not is_local_player:
		global_position = pos
		global_rotation = rot


@rpc("any_peer", "reliable")
func _sync_fire(pos: Vector2, rot: float) -> void:
	if is_local_player:
		return
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = pos
	bullet.rotation = rot
	bullet.shooter_id = player_id
	get_tree().current_scene.add_child(bullet)


func _on_fire_timer_timeout() -> void:
	can_fire = true
