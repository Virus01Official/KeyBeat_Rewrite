extends HSlider

func _on_value_changed(valuer: float) -> void:
	GameData.Scroll_Speed = valuer
