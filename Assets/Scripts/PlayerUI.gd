# UI.gd
extends CanvasLayer

@onready var health_value: Label = $MarginContainer/HBoxContainer/HealthValue
@onready var score_value: Label = $MarginContainer/HBoxContainer/ScoreValue

var health: int = 5
var score: int = 0

func _ready() -> void:
	update_health(health)
	update_score(score)

func update_health(value: int) -> void:
	health = value
	health_value.text = str(health)

func update_score(value: int) -> void:
	score = value
	score_value.text = str(score)
