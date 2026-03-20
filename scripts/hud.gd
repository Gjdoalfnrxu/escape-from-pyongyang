extends CanvasLayer

@onready var health_label: Label = $MarginContainer/HBox/HealthLabel
@onready var loot_label: Label = $MarginContainer/HBox/LootLabel
@onready var timer_label: Label = $MarginContainer/HBox/TimerLabel
@onready var extraction_label: Label = $ExtractionLabel

var raid_time := 600.0  # 10 minutes
var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	var remaining := max(0.0, raid_time - elapsed)
	var mins := int(remaining) / 60
	var secs := int(remaining) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if remaining <= 0:
		timer_label.modulate = Color.RED


func update_health(hp: int, max_hp: int) -> void:
	health_label.text = "HP: %d/%d" % [hp, max_hp]


func update_loot(carrying: bool) -> void:
	loot_label.text = "LOOT: %s" % ("CARRYING" if carrying else "—")
	loot_label.modulate = Color.YELLOW if carrying else Color.WHITE


func show_extraction_prompt(show: bool) -> void:
	extraction_label.visible = show
