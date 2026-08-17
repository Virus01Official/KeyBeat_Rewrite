extends Label
var time = Time.get_date_dict_from_system()
var tips = [
	"Also try osu!",
	"did you know, when you press S, you press S",
	"SOMEBODY SCREAM",
	"Godot is peak",
	"ALL MY FELLAS",
	"The difficulty is calculated automatically, report any calculation errors",
	"This game was made for fun",
	"You can use osu! to chart the songs",
	"Also try Project: RUSHER",
	"Also try Yunyun Syndrome",
	"Also try Nullscape",
	"DEATH IN BLOOM",
	"New KeyBeat game is in the works",
]

func _ready() -> void:
	if time.day == 1 and time.month == 4:
		text = "April Fools!"
	elif time.day == 23 and time.month == 6:
		text = "HAPPY KEYBEAT ANNIVERSARY!"
	elif time.month == 10:
		text = "IT IS A SPOOKY MONTH!"
	elif time.month == 12:
		if time.day != 31:
			text = "Merry Christmas!"
		else:
			text = "Happy New Year!"
	elif time.month == 6:
		text = "Happy Pride Month!"
	else:
		text = tips[randi() % tips.size()]
		if text == "DEATH IN BLOOM":
			modulate = Color.PURPLE
			add_theme_font_size_override("font_size", 32)
