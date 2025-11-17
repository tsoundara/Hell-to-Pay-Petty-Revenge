extends CanvasLayer

@export_file("*.json") var scene_text_file

var scene_text = {}       # all dialog from JSON
var selected_text = []    # current lines being displayed
var in_progress = false
var can_advance = false
var dialog_active = false

@onready var background = $Background
@onready var text_label = $TextLabel

func _ready():
	set_process_mode(ProcessMode.PROCESS_MODE_ALWAYS)
	background.visible = false
	# Load the JSON dialog
	if scene_text_file != null:
		scene_text = load_scene_text()
	else:
		print("No scene text file assigned!")
	# Connect to the global signal
	SignalBus.display_dialog.connect(on_display_dialog)
	print("DialogPlayer ready. Keys:", scene_text.keys())
	print("Signal connected: ", SignalBus.display_dialog.is_connected(on_display_dialog))

func load_scene_text():
	var file = FileAccess.open(scene_text_file, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	print("Loaded JSON:", data)
	return JSON.parse_string(file.get_as_text())

func show_text(): 
	if selected_text.size() == 0: 
		finish() 
		return 
	can_advance = false 
	await get_tree().create_timer(0.2).timeout 
	text_label.text = selected_text.pop_front() 
	can_advance = true

func next_line():
	show_text()

func _input(event):
	# Only advance dialog if a dialog is active and allowed to advance
	if in_progress and can_advance and event.is_action_pressed("ui_accept"):
		next_line()

func finish():
	text_label.text = ""
	background.visible = false
	in_progress = false
	get_tree().paused = false
	dialog_active = false
	SignalBus.emit_signal("dialog_finished")

func on_display_dialog(text_key):
	print("Signal received:", text_key)
	if dialog_active:
		return  # ignore new signals while a dialog is running
	if not scene_text.has(text_key):
		print("Key not found in JSON:", text_key)
		return

	dialog_active = true
	get_tree().paused = true
	background.visible = true
	in_progress = true
	selected_text = scene_text[text_key].duplicate()
	show_text()
