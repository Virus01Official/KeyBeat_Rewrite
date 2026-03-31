extends Label
func _process(delta: float) -> void:
	var time = Time.get_time_dict_from_system()
	var hour = time.hour % 12
	if hour == 0:
		hour = 12
	var suffix = "AM" if time.hour < 12 else "PM"
	text = "%02d:%02d:%02d %s" % [hour, time.minute, time.second, suffix]
