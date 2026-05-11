extends Control

const SETTINGS_PATH = "user://settings.mwdat"

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var data := {
		"audio": {
			"master_volume": $Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control2/Label/HSlider.value,
			"sfx_volume": $Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control3/Label/SFX_Slider.value
		},
		"gameplay": {
			"scroll_speed": GameData.Scroll_Speed
		},
		"display": {
			"show_fps": $"../Label".visible,
			"vsync": DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
		},
		"keybinds": {}
	}

	var actions = ["left", "right", "up", "down"]
	for action in actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				data["keybinds"][action] = event.keycode

	MWDat.save(SETTINGS_PATH, data)

func load_settings() -> void:
	var data := MWDat.load(SETTINGS_PATH)

	var audio: Dictionary = data.get("audio", {})
	var master_vol: float = audio.get("master_volume", 100.0)
	var sfx_vol: float = audio.get("sfx_volume", 100.0)
	$Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control2/Label/HSlider.value = master_vol
	$Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control3/Label/SFX_Slider.value = sfx_vol
	AudioServer.set_bus_volume_db(0, linear_to_db(master_vol / 100.0))
	AudioServer.set_bus_volume_db(1, linear_to_db(sfx_vol / 100.0))

	var gameplay: Dictionary = data.get("gameplay", {})
	var scroll_speed: float = gameplay.get("scroll_speed", 1.0)
	GameData.Scroll_Speed = scroll_speed
	$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/scroll_vel.value = scroll_speed
	$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/LineEdit.text = str(scroll_speed)

	var display: Dictionary = data.get("display", {})
	var show_fps: bool = display.get("show_fps", false)
	$"../Label".visible = show_fps
	$Panel/ScrollContainer/VBoxContainer/Control/VBoxContainer/Control3/Label/CheckBox.button_pressed = show_fps

	var vsync: bool = display.get("vsync", true)
	$Panel/ScrollContainer/VBoxContainer/Control/VBoxContainer/Control2/Label/CheckBox.button_pressed = vsync
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

	var keybinds: Dictionary = data.get("keybinds", {})
	for action in ["left", "right", "up", "down"]:
		if keybinds.has(action):
			var event = InputEventKey.new()
			event.keycode = keybinds[action]
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)

func _on_button_pressed() -> void:
	save_settings()
	var settings = $"."
	var screen_width = get_viewport().get_visible_rect().size.x
	var tween = create_tween()
	tween.tween_property(settings, "position:x", -screen_width, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): settings.visible = false)

func _on_h_slider_value_changed(valued: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(valued / 100.0))

func _on_sfx_slider_value_changed(valued: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(valued / 100.0))

func _on_scroll_vel_value_changed(valuer: float) -> void:
	GameData.Scroll_Speed = valuer
	if not $Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/LineEdit.is_editing():
		$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/LineEdit.text = str(valuer)

func _on_line_edit_text_changed(new_text: String) -> void:
	$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/scroll_vel.value = int(new_text)

func _on_FPS_check_box_toggled(toggled_on: bool) -> void:
	$"../Label".visible = toggled_on

func _on_vsync_check_box_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	)

func _on_skins_option_item_selected(index: int) -> void:
	pass
