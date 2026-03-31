extends Control

func _on_play_pressed() -> void:
	$"../play_menu".visible = true
	$".".visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	$SettingsUI.visible = true

func _on_credits_pressed() -> void:
	$credits.visible = true
