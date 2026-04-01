extends Control

func _on_play_pressed() -> void:
	$"../play_menu".visible = true
	$".".visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	var settings = $"../Settings"
	var screen_width = get_viewport().get_visible_rect().size.x
	var target_x = 0.0  

	settings.position.x = -screen_width
	settings.visible = true

	var tween = create_tween()
	tween.tween_property(settings, "position:x", target_x, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func _on_credits_pressed() -> void:
	$credits.visible = true
