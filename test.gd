extends Control
@export var scroll_speed: float = 40.0     
@export var smooth_scroll: bool = true
@export var smooth_speed: float = 10.0     
@export var drag_enabled: bool = true

var _content: Control         
var _target_offset: float = 0.0
var _current_offset: float = 0.0
var _drag_start_y: float = 0.0
var _drag_start_offset: float = 0.0
var _is_dragging: bool = false

# Touch/mobile support
var _touch_start_y: float = 0.0
var _touch_start_offset: float = 0.0
var _is_touch_dragging: bool = false
var _last_touch_y: float = 0.0
var _touch_velocity: float = 0.0
var _fling_active: bool = false

func _ready() -> void:
	if get_child_count() > 0:
		_content = get_child(0)
	else:
		push_error("CustomScroll: no child node found.")
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	if _content == null:
		return

	if _fling_active and not _is_touch_dragging:
		_target_offset = clampf(_target_offset + _touch_velocity, 0.0, _max_scroll())
		_touch_velocity *= 0.92  # friction
		if abs(_touch_velocity) < 0.5:
			_fling_active = false
			_touch_velocity = 0.0

	if smooth_scroll:
		_current_offset = lerp(_current_offset, _target_offset, smooth_speed * delta)
	else:
		_current_offset = _target_offset

	_content.position.y = -_current_offset

func _gui_input(event: InputEvent) -> void:
	if _content == null:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_is_touch_dragging = true
			_fling_active = false
			_touch_velocity = 0.0
			_touch_start_y = event.position.y
			_last_touch_y = event.position.y
			_touch_start_offset = _target_offset
			accept_event()
		else:
			_is_touch_dragging = false
			if abs(_touch_velocity) > 1.0:
				_fling_active = true
			accept_event()

	if event is InputEventScreenDrag:
		if _is_touch_dragging and drag_enabled:
			_touch_velocity = _last_touch_y - event.position.y
			_last_touch_y = event.position.y
			var delta_y: float = _touch_start_y - event.position.y
			_target_offset = clampf(
				_touch_start_offset + delta_y,
				0.0,
				_max_scroll()
			)
			accept_event()

	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_scroll_by(-scroll_speed)
					accept_event()
				MOUSE_BUTTON_WHEEL_DOWN:
					_scroll_by(scroll_speed)
					accept_event()
				MOUSE_BUTTON_LEFT:
					if drag_enabled:
						_is_dragging = true
						_drag_start_y = event.position.y
						_drag_start_offset = _target_offset
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_is_dragging = false

	if event is InputEventMouseMotion and _is_dragging:
		var delta_y: float = _drag_start_y - event.position.y
		_target_offset = clampf(
			_drag_start_offset + delta_y,
			0.0,
			_max_scroll()
		)
		accept_event()

func scroll_to(offset: float) -> void:
	_target_offset = clampf(offset, 0.0, _max_scroll())
	
func scroll_to_top() -> void:
	scroll_to(0.0)
	
func scroll_to_bottom() -> void:
	scroll_to(_max_scroll())
	
func scroll_to_child(node: Control) -> void:
	var local_y := node.get_rect().position.y
	scroll_to(local_y)
	
func get_scroll_offset() -> float:
	return _target_offset
	
func get_max_scroll() -> float:
	return _max_scroll()
	
func _scroll_by(amount: float) -> void:
	_target_offset = clampf(_target_offset + amount, 0.0, _max_scroll())
	
func _max_scroll() -> float:
	if _content == null:
		return 0.0
	var overflow := _content.size.y - size.y
	return maxf(overflow, 0.0)
