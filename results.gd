extends Control


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var game = $"../game"
	var grade = game.final_grade
	
	if grade == "":
		return  # don't try to load yet
		
	$grade.texture = load("res://assets/grades/" + grade + ".png")
