extends HSlider

func _on_value_changed(valuer: float) -> void:
	GameData.Scroll_Speed = valuer
	$"../LineEdit".text = str(valuer)
	
func _on_line_edit_text_changed(new_text: String) -> void:
	value = int(new_text)
