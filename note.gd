extends Control
@onready var tail = $Tail

var direction: String = ""
var speed: float = GameData.Scroll_Speed
var duration: float = 0.0
var is_hold: bool = false
var hold_active: bool = false

func init_tail() -> void:
	is_hold = duration > 0.0
	tail.visible = is_hold
	if is_hold:
		tail.size.y = duration * speed
		tail.position.y = 64

func _process(delta: float) -> void:
	if hold_active:
		return  
	position.y -= speed * delta
	if position.y < -100:
		queue_free()
