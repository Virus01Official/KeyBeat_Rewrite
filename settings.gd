extends Control

func _on_button_pressed() -> void:
	var settings = $"."
	var screen_width = get_viewport().get_visible_rect().size.x

	var tween = create_tween()
	tween.tween_property(settings, "position:x", -screen_width, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)  

	tween.tween_callback(func(): settings.visible = false)
