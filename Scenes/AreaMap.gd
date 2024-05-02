extends Node2D

func _ready():
	$DrawnMap.style = GameGlobals.styleData
	$DrawnMap.showCurrentLocation = true
	Draw(PraxisCore.currentPlusCode, null)
	
	GameGlobals.pluscode_changed.connect(Draw)
	
	var area = PraxisCore.currentPlusCode.substr(0,6)
	var nextArea = PlusCodes.ShiftCode(area, 1, 1)
	
	var swCorner = PlusCodes.Decode(area)
	#These are always Cell6 sized, so I dont need to calculate that. Just need to know my latitude
	var distHorizontal = PraxisCore.DistanceDegreesToMetersLon(PraxisCore.resolutionCell6, swCorner.y)
	var distVertical = PraxisCore.DistanceDegreesToMetersLat(PraxisCore.resolutionCell6)
	print("area size: " + str(distHorizontal) + " x " + str(distVertical))
	var scale = "Scale:\n"
	scale += str(snapped(distHorizontal / 1000, 0.1)) + "x " + str(snapped(distVertical / 1000, 0.1)) + "km\n"
	scale += str(snapped(distHorizontal * 3.281 / 5280, 0.1)) + "x " + str(snapped(distVertical * 3.281 / 5280, 0.1)) + "mi\n"
	$lblScale.text = scale

	$DrawnMap.scale.x *= (distHorizontal / distVertical)

func Draw(current, _new):
	var area = current.substr(0,6)
	var data = MinimizedOffline.GetDataFromZip(area)
	
	$DrawnMap.DrawOfflineTile(data.entries["suggestedmini"],1)

func Close():
	queue_free()
