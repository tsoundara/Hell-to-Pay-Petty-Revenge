extends Node2D

@export var dialog_key: String = "commissioner"

func _ready():
	print("Level ready, about to emit signal")
	await get_tree().create_timer(1.25).timeout  # Small delay
	SignalBus.display_dialog.emit("commissioner")
	print("Signal emitted")
