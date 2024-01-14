class_name PewPew
extends Area2D

@export var SPEED: float = 1600.0
@export var DISTANCE: float = 1200.0

var _owning_player: Node2D

func _ready():
	$LifetimeTimer.start(DISTANCE / SPEED)

func _physics_process(delta):
	position.x += SPEED * delta

func _on_timer_timeout():
	queue_free()

func _on_tree_exiting():
	_owning_player.decrement_pew_pews()
