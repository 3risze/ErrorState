extends Node

var created_files: Array[String] = []
var glitch_enabled: bool = true
var ending_status: String = "" # "", "PURGED", atau "COEXIST"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q and event.ctrl_pressed and event.shift_pressed:
			trigger_failsafe()

func register_file(file_path: String) -> void:
	if not created_files.has(file_path):
		created_files.append(file_path)

func cleanup_all_files() -> void:
	for file_path in created_files:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)
	created_files.clear()

func trigger_failsafe() -> void:
	cleanup_all_files()
	OS.alert(
		"Relax, this is just a psychological horror simulation! Your system is completely safe and all temporary game files have been cleaned up.",
		"Safe Mode - Error_State"
	)
	get_tree().quit()
