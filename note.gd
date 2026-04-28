extends Control
@onready var tail = $Tail

var direction: String = ""
var duration: float = 0.0
var is_hold: bool = false
var hold_active: bool = false
var is_stun: bool = false

func _ready():
	if is_stun:
		modulate = Color(0.254, 0.664, 0.0, 1.0)

func init_tail(spawn_speed: float) -> void:
	is_hold = duration > 0.0
	tail.visible = is_hold
	if is_hold:
		tail.size.y = duration * spawn_speed
		tail.position.y = 64

func _process(_delta: float) -> void:
	if hold_active:
		return  
	
	if position.y < -100:
		queue_free()
		
func move(delta: float, current_speed: float) -> void:
	if not hold_active:
		position.y -= current_speed * delta
