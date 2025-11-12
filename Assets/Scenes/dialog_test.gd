extends Node2D

@export var dialog_key: String = "npc_intro"

func _input(event):
	if event.is_action_pressed("ui_accept"): # default: Enter or Space
		SignalBus.display_dialog.emit(dialog_key)
