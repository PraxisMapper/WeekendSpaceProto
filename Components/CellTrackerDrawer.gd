extends Node2D

var plusCode8
var visited = {}
var timeToSwitch = 0
var colorIndicator = Color.DARK_RED

func DrawCellTracker(cellTracker, plusCode):
	visited = cellTracker.visited
	plusCode8 = plusCode
	queue_redraw()

func _draw():
	#This is drawing cell10s in a Cell8, so this is a 20x20 grid
	#Coordinate space: 0,0 is the position of the CellTrackerDrawer node in the scene
	#bigger X is right, bigger Y is down.
	
	if plusCode8 == null:
		return
	
	draw_rect(Rect2(0, 0, 20 , 20), Color.DIM_GRAY)

	for key in visited.keys():
		if key.begins_with(plusCode8):
			var yCoord = PlusCodes.GetLetterIndex(key[8])
			var xCoord = PlusCodes.GetLetterIndex(key[9])
			draw_rect(Rect2(xCoord, 19 - yCoord, 1, 1), Color.ANTIQUE_WHITE)
	
	if PraxisCore.currentPlusCode == "":
		return
	
	if (PraxisCore.currentPlusCode.begins_with(plusCode8)):
		var code = PraxisCore.currentPlusCode.replace("+", "")
		var yCoord = PlusCodes.GetLetterIndex(code[8])
		var xCoord = PlusCodes.GetLetterIndex(code[9])
		draw_rect(Rect2(xCoord, 19 - yCoord, 1, 1), colorIndicator)

func _process(delta):
	timeToSwitch += delta
	if (timeToSwitch >= 1):
		timeToSwitch -= 1
		if colorIndicator == Color.DARK_RED:
			colorIndicator = Color.LIME_GREEN
		else:
			colorIndicator = Color.DARK_RED
		queue_redraw()
