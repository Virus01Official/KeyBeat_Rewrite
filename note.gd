extends Control

var direction: String = ""
var speed: float = 300.0

func _process(delta: float) -> void:
	position.y -= speed * delta
	# Remove note if it goes off screen
	if position.y < -100:  # was: > get_viewport_rect().size.y + 100
		queue_free()
