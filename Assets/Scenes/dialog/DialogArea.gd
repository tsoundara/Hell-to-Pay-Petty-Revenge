extends Area2D

@export var dialog_key = ""
@export var next_scene_path = ""

var area_active = false
var dialog_started = false

func _ready():
	set_process_mode(ProcessMode.PROCESS_MODE_ALWAYS)
	

func _input(event):
	if area_active and event.is_action_pressed("ui_accept"):
		if not dialog_started:
			dialog_started = true

			# Locked door
			if (dialog_key == "door_locked"):
				if "letters_dialog" in Player.interacted_objects and "tv_dialog" in Player.interacted_objects:
					dialog_key = "door_unlocked"
					print("Door unlocked!")
					SignalBus.emit_signal("display_dialog", "door_unlocked")
					await SignalBus.dialog_finished
					get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")
				else:
					print("Door locked!")
					SignalBus.emit_signal("display_dialog", "door_locked")
				return

			# Other object interactions
			if dialog_key != "":
				SignalBus.emit_signal("display_dialog", dialog_key)
				Player.mark_interacted(dialog_key)

			# Debug
			print("=== INTERACTED OBJECTS ===")
			print(Player.interacted_objects)
			print("==========================")

func _on_area_entered(area):
	if area_active:
		return
	print("Entered area!")
	area_active = true
	dialog_started = false

func _on_area_exited(area):
	if not area_active:
		return
	print("Exited area!")
	area_active = false
