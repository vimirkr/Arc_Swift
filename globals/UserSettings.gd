# res://globals/UserSettings.gd
extends Node

# --- Colorblind Mode ---
enum ColorMode { DEFAULT, DEUTERANOPIA, TRITANOPIA }
var current_color_mode = ColorMode.DEFAULT
const PALETTES = {
	ColorMode.DEFAULT: {"side1": Color.BLUE, "side2": Color.MAGENTA, "center1": Color.YELLOW, "center2": Color.LIME_GREEN, "double": Color.PURPLE},
	ColorMode.DEUTERANOPIA: {"side1": Color.BLUE, "side2": Color.ORANGE, "center1": Color.SKY_BLUE, "center2": Color.WHITE, "double": Color.TEAL},
	ColorMode.TRITANOPIA: {"side1": Color.RED, "side2": Color.ORANGE, "center1": Color.TEAL, "center2": Color.WHITE, "double": Color.LIGHT_GRAY}
}
func set_color_mode(mode: ColorMode): current_color_mode = mode
func get_note_color(note_type: String) -> Color: return PALETTES[current_color_mode][note_type]

# --- Low Specification Mode ---
var low_spec_mode_on = false
func set_low_spec_mode(is_on: bool): low_spec_mode_on = is_on

# --- Audio Volume Settings ---
var master_volume: float = 10.0
var music_volume: float = 10.0
var sfx_volume: float = 10.0
var ui_volume: float = 10.0

# [FINAL CORRECTED VERSION]
# Helper function to convert linear volume (0-10) to decibels (-80 to 0)
static func linear_to_db_custom(linear_val: float) -> float:
	if linear_val <= 0:
		return -80.0
	# Use the global scope linear_to_db function, which is correct for Godot 4.x
	# The function name is NOT linear2db.
	return linear_to_db(linear_val / 10.0)

static func set_bus_volume(bus_name: String, linear_val: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		# Use the corrected custom function name
		AudioServer.set_bus_volume_db(bus_index, linear_to_db_custom(linear_val))

func set_master_volume(value: float):
	master_volume = value
	set_bus_volume("Master", value)

func set_music_volume(value: float):
	music_volume = value
	set_bus_volume("Music", value)

func set_sfx_volume(value: float):
	sfx_volume = value
	set_bus_volume("SFX", value)

func set_ui_volume(value: float):
	ui_volume = value
	set_bus_volume("UI", value)
