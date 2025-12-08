extends Area2D

@export var dialog_key = ""
@export var next_scene_path = ""

var area_active = false
var dialog_started = false

var outline_target: Node = null

func _ready():
	set_process_mode(ProcessMode.PROCESS_MODE_ALWAYS)
	outline_target = _find_outline_target_upwards(self)
	print("Outline target for", self.get_path(), "is", outline_target)


# Search child nodes for node with ShaderMaterial
func _find_outline_target(node: Node) -> Node:
	for child in node.get_children():
		var found = _find_outline_target(child)
		if found:
			return found

		if child is CanvasItem:
			var mat = null
			if "material" in child:
				mat = child.material
			elif child.has_method("get"):
				mat = child.get("material")

			if mat is ShaderMaterial:
				return child

	return null


# Turn outline on or off
func _set_outline_enabled(enabled: bool) -> void:
	if not outline_target:
		return

	var mat = outline_target.material
	if not (mat is ShaderMaterial):
		return

	mat.set_shader_parameter("outline_enabled", enabled)  # Change shader parameter


func _input(event):
	if area_active and event.is_action_pressed("ui_accept"):
		if not dialog_started:
			dialog_started = true

			if dialog_key == "door_locked":
				if "letters_dialog" in Player.interacted_objects and "tv_dialog" in Player.interacted_objects:
					dialog_key = "door_unlocked"
					SignalBus.emit_signal("display_dialog", "door_unlocked")
					await SignalBus.dialog_finished
					get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")
				else:
					SignalBus.emit_signal("display_dialog", "door_locked")
				return

			if dialog_key != "":
				SignalBus.emit_signal("display_dialog", dialog_key)
				Player.mark_interacted(dialog_key)

			print("=== INTERACTED OBJECTS ===")
			print(Player.interacted_objects)
			print("==========================")

# Search parent nodes for node with ShaderMaterial
func _find_outline_target_upwards(node: Node) -> Node:
	var current = node.get_parent()

	while current:
		if current is CanvasItem and current.material is ShaderMaterial:
			return current

		for child in current.get_children():
			if child is CanvasItem and child.material is ShaderMaterial:
				return child

		current = current.get_parent()

	return null

# When player enters area, turn on outline
func _on_area_entered(area):
	if area_active:
		return
	area_active = true
	dialog_started = false
	_set_outline_enabled(true)  # Show outline

# When player exits area, turn off outline
func _on_area_exited(area):
	if not area_active:
		return
	area_active = false
	_set_outline_enabled(false)  # Hide outline
