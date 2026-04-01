extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var game = $"../game"
	var grade = game.final_grade
	
	var accurancy = game.final_accuracy
	var combo = game.highest_combo
	
	if grade == "":
		return  # don't try to load yet
		
	$grade.texture = load("res://assets/grades/" + grade + ".png")
	$VBoxContainer/Accurancy.text = "Accurancy: " + str(floor(accurancy)) + "%"
	$VBoxContainer/Combo.text = "Highest combo: " + str(combo)
	$VBoxContainer/Score.text = "Score: " + str(game.score)
	
	$backgorund.texture = game.get_node("background").texture
	
	$VBoxContainer/Perfect.text = "Perfect: " + str(game.perfect)
	$VBoxContainer/Great.text = "Great: " + str(game.great)
	$VBoxContainer/Good.text = "Good: " + str(game.good)
	$VBoxContainer/Okay.text = "Okay: " + str(game.ok)
	$VBoxContainer/Bad.text = "Bad: " + str(game.meh)
	$VBoxContainer/Misses.text = "Misses: " + str(game.misses)


func _on_button_pressed() -> void:
	$".".visible = false
	$"../play_menu".visible = true
