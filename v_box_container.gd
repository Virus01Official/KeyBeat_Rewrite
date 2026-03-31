extends Control

@export var separation: float = 100.0
@export var height_per_difficulty: float = 70.0

func _ready() -> void:
	child_entered_tree.connect(_on_child_changed)
	child_exiting_tree.connect(_on_child_changed)

func _on_child_changed(_node) -> void:
	await get_tree().process_frame
	recalculate()

func recalculate() -> void:
	var y_offset = 0.0
	for category in get_children():
		if not category.visible:  
			continue             
		category.position.x = 0
		category.position.y = y_offset
		category.size.x = size.x

		var inner_vbox = category.get_node_or_null("Category/ScrollContainer/VBoxContainer")
		var item_count = 1
		if inner_vbox != null:
			item_count = max(inner_vbox.get_child_count(), 1)

		var category_height = (item_count * height_per_difficulty)
		category.custom_minimum_size.y = category_height
		category.size.y = category_height

		y_offset += category_height + separation

	custom_minimum_size.y = y_offset
	size.y = y_offset
