extends Node2D

#This will fire off some tweens

var avgHue = 0.7 #range of 0 to 1. 0 is red, .33 is green, .66 is blue.
var avgAngle = -75 #0 is vertical, so start near the bottom of the -90 to 90 range
var avgTime = 2.0


# Called when the node enters the scene tree for the first time.
func _ready():
	TweenThis()

func SetVals(hue, angle, time):
	avgHue = hue
	avgAngle = angle
	avgTime = time

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func TweenThis():
	var nextHue = avgHue + randf_range(-0.1, 0.1)
	var nextAngle = avgAngle + randi_range(-20, 20)
	var nextTime = avgTime * randf_range(0.70, 1.3)
	
	var nextColor = Color.from_hsv(nextHue, 0.5, 0.9)
		
	var tweenA = create_tween()
	tweenA.tween_property($line, 'rotation', deg_to_rad(nextAngle), nextTime)
	var tweenB = create_tween()
	tweenB.tween_property($bg, 'modulate', nextColor, 0.2)
	await get_tree().create_timer(2.0 * randf()).timeout
	tweenA.tween_callback(TweenThis)

