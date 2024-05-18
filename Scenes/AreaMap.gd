extends Node2D

func _ready():
	$DrawnMap.style = GameGlobals.styleData
	$DrawnMap.showCurrentLocation = true
	Draw(PraxisCore.currentPlusCode, null)
	
	GameGlobals.pluscode_changed.connect(Draw)
	
	var area = PraxisCore.currentPlusCode.substr(0,6)
	
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
	if FileAccess.file_exists("user://MapTiles/" + area + "-thumb.png"):
		$TextureRect.visible = true
		$fullMapLines.visible = true
		$DrawnMap.visible = false
		$TextureRect.texture = ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + area + "-thumb.png"))
		$lblMapKey.visible = false
		#TODO: draw intersecting lines here over this image. Texture is 512x800
		#but area is 320x500, so multiply results by 1.6
		var code10 = current.replace("+", "")
		#Y is correct at the bottom, not at the top
		#These coords are 400x400. Im scaling them wrong. 
		$fullMapLines.y = 799 - ((PlusCodes.GetLetterIndex(code10[6]) * 20) + (PlusCodes.GetLetterIndex(code10[8]))) * 2
		#x is correct on left, not on right. Scaling is too big?
		$fullMapLines.x = ((PlusCodes.GetLetterIndex(code10[7]) * 20) + (PlusCodes.GetLetterIndex(code10[9]))) * 1.28
		$fullMapLines.queue_redraw()
	else:
		$DrawnMap.visible = true
		$fullMapLines.visible = false
		var data = MinimizedOffline.GetDataFromZip(area)
		$DrawnMap.DrawOfflineTile(data.entries["suggestedmini"],1)
		$TextureRect.visible = false
		$lblMapKey.visible = true

func Close():
	queue_free()
