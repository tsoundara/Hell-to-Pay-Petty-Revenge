extends Area2D

@export var dialog_key = ""
var area_active = false
var dialog_started = false

func _ready():
	set_process_mode(ProcessMode.PROCESS_MODE_ALWAYS)

func _input(event):
	if area_active and event.is_action_pressed("ui_accept"):
		if not dialog_started:   # only trigger once
			dialog_started = true
			print("ui_accept pressed. Dialog key:", dialog_key)
			if dialog_key != "":
				SignalBus.emit_signal("display_dialog", dialog_key)

func _on_area_entered(area):
	if area_active:
		return
	print("Entered area!")
	area_active = true
	dialog_started = false   # reset trigger when entering

func _on_area_exited(area):
	if not area_active:
		return
	print("Exited area!")
	area_active = false
