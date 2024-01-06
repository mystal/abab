extends Camera2D

@export var MinLimitNode: Node2D = null
@export var MaxLimitNode: Node2D = null

func _ready():
	# TODO: Validate min and max limits.
	if MinLimitNode != null:
		limit_left = int(MinLimitNode.global_position.x)
		limit_top = int(MinLimitNode.global_position.y)
	if MaxLimitNode != null:
		limit_right = int(MaxLimitNode.global_position.x)
		limit_bottom = int(MaxLimitNode.global_position.y)
