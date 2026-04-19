extends Control

@export var scroll_speed: float = 40.0
@export var smooth_scroll: bool = true
@export var smooth_speed: float = 10.0
@export var drag_enabled: bool = true

@export var fling_friction: float = 4.5
@export var fling_min_speed: float = 80.0    
@export var fling_stop_threshold: float = 2.0

var _content: Control
var _target_offset: float = 0.0
var _current_offset: float = 0.0

var _drag_start_y: float = 0.0
var _drag_start_offset: float = 0.0
var _is_dragging: bool = false

var _touch_id: int = -1
var _touch_start_y: float = 0.0
var _touch_start_offset: float = 0.0
var _last_touch_y: float = 0.0
var _is_touch_dragging: bool = false

var _fling_velocity: float = 0.0       
var _fling_active: bool = false

const VELOCITY_SAMPLE_COUNT = 5
var _velocity_samples: Array[float] = []

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
		_target_offset = clampf(_target_offset + _fling_velocity * delta, 0.0, _max_scroll())
		_fling_velocity = move_toward(_fling_velocity, 0.0, fling_friction * abs(_fling_velocity) * delta)
		if abs(_fling_velocity) < fling_stop_threshold:
			_fling_active = false
			_fling_velocity = 0.0

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
			if _touch_id == -1:
				_touch_id = event.index
				_is_touch_dragging = true
				_fling_active = false
				_fling_velocity = 0.0
				_velocity_samples.clear()
				_touch_start_y = event.position.y
				_last_touch_y = event.position.y
				_touch_start_offset = _target_offset
				accept_event()
		else:
			if event.index == _touch_id:
				_touch_id = -1
				_is_touch_dragging = false
				# Commit fling only if fast enough
				var avg_vel := _get_average_velocity()
				if abs(avg_vel) > fling_min_speed:
					_fling_velocity = avg_vel
					_fling_active = true
				_velocity_samples.clear()
				accept_event()

	if event is InputEventScreenDrag:
		if event.index == _touch_id and _is_touch_dragging and drag_enabled:
			_velocity_samples.append(event.velocity.y)
			if _velocity_samples.size() > VELOCITY_SAMPLE_COUNT:
				_velocity_samples.pop_front()

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
	scroll_to(node.get_rect().position.y)

func get_scroll_offset() -> float:
	return _target_offset

func get_max_scroll() -> float:
	return _max_scroll()

func _scroll_by(amount: float) -> void:
	_target_offset = clampf(_target_offset + amount, 0.0, _max_scroll())

func _max_scroll() -> float:
	if _content == null:
		return 0.0
	return maxf(_content.size.y - size.y, 0.0)

func _get_average_velocity() -> float:
	if _velocity_samples.is_empty():
		return 0.0
	var total := 0.0
	for v in _velocity_samples:
		total += v
	return total / _velocity_samples.size()
