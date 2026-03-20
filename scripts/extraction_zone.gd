extends Area2D

signal player_extracting(player_id: int)

@onready var label: Label = $Label
@onready var progress: ProgressBar = $ProgressBar
@onready var extract_timer: Timer = $ExtractTimer

const EXTRACT_TIME := 3.0

var extracting_player: CharacterBody2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	extract_timer.wait_time = EXTRACT_TIME
	extract_timer.timeout.connect(_on_extract_complete)
	progress.max_value = EXTRACT_TIME
	progress.value = 0
	label.text = "EXTRACTION"


func _process(delta: float) -> void:
	if extracting_player != null and not extract_timer.is_stopped():
		progress.value = EXTRACT_TIME - extract_timer.time_left


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		extracting_player = body
		extract_timer.start()
		progress.visible = true


func _on_body_exited(body: Node) -> void:
	if body == extracting_player:
		extracting_player = null
		extract_timer.stop()
		progress.value = 0
		progress.visible = false


func _on_extract_complete() -> void:
	if extracting_player != null:
		player_extracting.emit(extracting_player.player_id)
		get_node("/root/GameManager").on_player_reached_extraction(extracting_player.player_id)
