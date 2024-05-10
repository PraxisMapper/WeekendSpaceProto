extends Node2D

#This is too slow for normal use. It's also nearly impossible to see where you are and what
#progress you've made until you've done quite a bit in a small area.
#Keeping this code around for reference, but probably won't use it.

var indColor1 = Color.DARK_RED
var indColor2 = Color.LIME_GREEN

var plusCode6
var visited = {}
var timeToSwitch = 0
var colorIndicator = indColor1
@export var transparent = false

func DrawCellTracker(cellTracker, plusCode):
	visited = cellTracker.visited
	plusCode6 = plusCode.substr(0,6)
	queue_redraw()

func _draw():
	#This is drawing cell10s in a Cell8, so this is a 20x20 grid
	#Coordinate space: 0,0 is the position of the CellTrackerDrawer node in the scene
	#bigger X is right, bigger Y is down.
	
	if plusCode6 == null:
		return
	
	var bgColor = Color.DIM_GRAY
	var visitedColor = Color.ANTIQUE_WHITE
	if transparent:
		
		bgColor.a = 0.6
		visitedColor.a = 0.6
		indColor1.a = 0.5
		indColor2.a = 0.5
	
	#This one actually takes quite a bit to draw, so cutting it down this way:
	draw_rect(Rect2(0, 0, 399, 399), bgColor)
	
	#redoing this, so exploring brightens up a cell over the drawn map
	#draw_rect(Rect2(0, 0, 20 , 20), bgColor)
	var charListX = PlusCodes.CODE_ALPHABET_
	var charListY = PlusCodes.CODE_ALPHABET_
	
	for xval8 in charListX:
		var xCoord8 = PlusCodes.GetLetterIndex(xval8) * 20
		for yval8 in charListY:
			var yCoord8 = PlusCodes.GetLetterIndex(yval8) * 20
			for xval10 in charListX:
				for yval10 in charListY:
					var xCoord = PlusCodes.GetLetterIndex(xval10)
					var yCoord = PlusCodes.GetLetterIndex(yval10)
					if visited.has(plusCode6 + yval8 + xval8 + yval10 + xval10 ):
						draw_rect(Rect2(xCoord8 + xCoord, 399 - yCoord8 - yCoord, 1, 1), visitedColor)
					#else:
						#draw_rect(Rect2(xCoord8 + xCoord, 399 - yCoord8 - yCoord, 1, 1), bgColor)
	
	if PraxisCore.currentPlusCode == "":
		return
	
	if (PraxisCore.currentPlusCode.begins_with(plusCode6)):
		var code = PraxisCore.currentPlusCode.replace("+", "")
		var yCoord = PlusCodes.GetLetterIndex(code[6]) * 20  + PlusCodes.GetLetterIndex(code[8])
		var xCoord = PlusCodes.GetLetterIndex(code[7]) * 20 + PlusCodes.GetLetterIndex(code[9])
		draw_rect(Rect2(xCoord, 399 - yCoord, 1, 1), colorIndicator)

#func _process(delta):
	#timeToSwitch += delta
	#if (timeToSwitch >= 1):
		#timeToSwitch -= 1
		#if colorIndicator == indColor1:
			#colorIndicator = indColor2
		#else:
			#colorIndicator = indColor1
		#queue_redraw()
