extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var players = get_tree().get_nodes_in_group("players")
	var player1 = players[0]
	var player2 = players[1]
	text = "P1: " + str(player1._lives) + "\nP2: " + str(player2._lives)
