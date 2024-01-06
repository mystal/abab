extends Node2D

@export var AMPLITUDE_Y: float = 12.0
@export var PERIOD: float = 3.0

func _ready():
	pass

func _process(_delta):
	var ticks_float = float(Time.get_ticks_msec()) / 1000.0
	position.y = sin((ticks_float * 2.0 * PI) / PERIOD) * AMPLITUDE_Y
