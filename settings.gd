extends Control

const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", $Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control2/Label/HSlider.value)
	config.set_value("audio", "sfx_volume", $Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control3/Label/SFX_Slider.value)
	config.set_value("gameplay", "scroll_speed", GameData.Scroll_Speed)
	config.set_value("display", "show_fps", $"../Label".visible)
	config.set_value("display", "vsync", DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED)
	
	var actions = ["left", "right", "up", "down"]
	for action in actions:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				config.set_value("keybinds", action, event.keycode)
	
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return  # nyothing saved yet, use defaults uwu
	
	var master_vol = config.get_value("audio", "master_volume", 100.0)
	var sfx_vol = config.get_value("audio", "sfx_volume", 100.0)
	$Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control2/Label/HSlider.value = master_vol
	$Panel/ScrollContainer/VBoxContainer/Control2/VBoxContainer/Control3/Label/SFX_Slider.value = sfx_vol
	AudioServer.set_bus_volume_db(0, linear_to_db(master_vol / 100.0))
	AudioServer.set_bus_volume_db(1, linear_to_db(sfx_vol / 100.0))
	
	var scroll_speed = config.get_value("gameplay", "scroll_speed", 1.0)
	GameData.Scroll_Speed = scroll_speed
	$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/scroll_vel.value = scroll_speed
	$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/LineEdit.text = str(scroll_speed)
	
	var show_fps = config.get_value("display", "show_fps", false)
	$"../Label".visible = show_fps
	$Panel/ScrollContainer/VBoxContainer/Control/VBoxContainer/Control3/Label/CheckBox.button_pressed = show_fps
	
	var vsync = config.get_value("display", "vsync", true)
	$Panel/ScrollContainer/VBoxContainer/Control/VBoxContainer/Control2/Label/CheckBox.button_pressed = vsync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
	var actions = ["left", "right", "up", "down"]
	for action in actions:
		if config.has_section_key("keybinds", action):
			var keycode = config.get_value("keybinds", action)
			var event = InputEventKey.new()
			event.keycode = keycode
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
	var db = linear_to_db(valued / 100.0)
	AudioServer.set_bus_volume_db(0, db)

func _on_sfx_slider_value_changed(valued: float) -> void:
	var db = linear_to_db(valued / 100.0)
	AudioServer.set_bus_volume_db(1, db)

func _on_scroll_vel_value_changed(valuer: float) -> void:
	GameData.Scroll_Speed = valuer
	if not $Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/LineEdit.is_editing():
		$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/LineEdit.text = str(valuer)

func _on_line_edit_text_changed(new_text: String) -> void:
	$Panel/ScrollContainer/VBoxContainer/Control3/VBoxContainer/Control3/Label/scroll_vel.value = int(new_text)

func _on_FPS_check_box_toggled(toggled_on: bool) -> void:
	$"../Label".visible = toggled_on

func _on_vsync_check_box_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

func _on_skins_option_item_selected(index: int) -> void:
	pass
