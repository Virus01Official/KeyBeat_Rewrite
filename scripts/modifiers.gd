extends Node

var no_fail = false
var hidden = false
var sudden_death = false

var multiplier = 1.0

func _process(_delta: float) -> void:
	if no_fail:
		multiplier -= 0.25
	if hidden:
		multiplier += 0.25
	if sudden_death:
		multiplier += 0.50
