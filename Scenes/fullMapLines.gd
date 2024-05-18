extends Node2D

var x = 0
var y = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _draw():
	draw_line(Vector2(x, 0), Vector2(x, 800), Color.RED, 2)
	draw_line(Vector2(0, y), Vector2(512, y), Color.RED, 2)
