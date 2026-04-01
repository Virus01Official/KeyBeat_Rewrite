extends CheckBox

func _on_toggled(toggled_on: bool) -> void:
	$"../../../../../../../Label".visible = toggled_on
