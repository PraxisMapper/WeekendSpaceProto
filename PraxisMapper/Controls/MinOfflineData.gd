extends Node2D

#This is already offline data, we need to load it from the current program's
#res://OfflineData folder.

signal tiles_saved()

var plusCode = ""
var style = "suggestedmini"
var scaleVal = 1
var mapData

func GetAndProcessData(pluscode6, styleSet):
	print("Triple-processing minimized data")
	plusCode = pluscode6
	scaleVal = 1
	style = styleSet
	await GetStyle()
	mapData = await GameGlobals.GetDataFromZip(pluscode6)
	print("begin tile making for " + pluscode6)
	await CreateAllTiles()
	
func GetStyle():
	var styleData = FileAccess.open("res://PraxisMapper/Styles/" + style + ".json", FileAccess.READ)
	if (styleData == null):
		print("HEY DEV - go make and save the style json here!")
	else:
		var json = JSON.new()
		json.parse(styleData.get_as_text())
		var info = json.get_data()
		$svc/SubViewport/fullMap.style = info
		$svc2/SubViewport/nameMap.style = info
		$svc4/SubViewport/terrainMap.style = info
		styleData.close()

func GetData():
	var locationData = FileAccess.open("user://Offline/" + plusCode + ".json", FileAccess.READ)
	if (locationData == null):
		print("HEY DEV - minOffline failed to get data.")
	else:
		var json = JSON.new()
		json.parse(locationData.get_as_text())
		mapData = json.get_data()
		locationData.close()

func CreateAllTiles():
	#This is Cell6 data drawn with Cell10 pixels, so each image is 400x400
	#I don't need to subdivide these images any further.
	#Bounds was removed, since the minimized data doesn't contain that info.
	
	$svc/SubViewport/fullMap.position.y = 0
	$svc2/SubViewport/nameMap.position.y = 400
	#$svc3/SubViewport/boundsMap.position.y = 800
	$svc4/SubViewport/terrainMap.position.y = 1200
	
	$svc/SubViewport/fullMap.DrawOfflineTile(mapData.entries["suggestedmini"], scaleVal)
	$svc2/SubViewport/nameMap.DrawOfflineNameTile(mapData.entries["suggestedmini"], scaleVal)
	#$svc3/SubViewport/boundsMap.DrawOfflineBoundsTile(mapData.entries["adminBoundsFilled"], scaleVal)
	$svc4/SubViewport/terrainMap.DrawOfflineTerrainTile(mapData.entries["suggestedmini"], scaleVal)
	
	var viewport1 = $svc/SubViewport
	var viewport2 = $svc2/SubViewport
	#var viewport3 = $svc3/SubViewport
	var viewport4 = $svc4/SubViewport
	var camera1 = $svc/SubViewport/subcam
	var camera2 = $svc2/SubViewport/subcam
	#var camera3 = $svc3/SubViewport/subcam
	var camera4 = $svc4/SubViewport/subcam
	var scale = scaleVal
	
	camera1.position = Vector2(0,-400)
	camera2.position = Vector2(0,0)
	#camera3.position = Vector2(400,8000)
	camera4.position = Vector2(0,800)
	viewport1.size = Vector2i(400 * scale, 400 * scale)
	viewport2.size = Vector2i(400 * scale, 400 * scale)
	#viewport3.size = Vector2i(400 * scale, 400 * scale)
	viewport4.size = Vector2i(400 * scale, 400 * scale)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	
	var img1 = viewport1.get_texture().get_image() # Get rendered image
	img1.save_png("user://MapTiles/" + plusCode + ".png") # Save to disk
	var img2 = viewport2.get_texture().get_image() # Get rendered image
	img2.save_png("user://NameTiles/" + plusCode + ".png") # Save to disk
	#var img3 = viewport3.get_texture().get_image() # Get rendered image
	#img3.save_png("user://BoundsTiles/" + plusCode + yChar + xChar + ".png") # Save to disk
	var img4 = viewport4.get_texture().get_image() # Get rendered image
	img4.save_png("user://TerrainTiles/" + plusCode + ".png") # Save to disk
	print("Saved minimized tile for " + plusCode)
	
	tiles_saved.emit()
