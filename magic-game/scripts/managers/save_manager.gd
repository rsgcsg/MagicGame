extends Node

const PROFILE_SAVE_PATH := "user://profile_save.json"
const RUN_SAVE_PATH := "user://run_save.json"

func save_profile_placeholder() -> void:
	print("SaveManager placeholder: profile save would write to %s" % PROFILE_SAVE_PATH)

func load_profile_placeholder() -> Dictionary:
	print("SaveManager placeholder: profile load would read from %s" % PROFILE_SAVE_PATH)
	return {}
