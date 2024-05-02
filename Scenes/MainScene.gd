extends Node2D

signal pluscode_changed(current, old)
signal place_changed(newPlaceName)

func _process(delta):
	var heading = PraxisCore.GetCompassHeading()
	$compassTexture.rotation = heading
	$lblHeading.text = "Heading: " + str(snapped(rad_to_deg(heading), 0))

func _ready():
	GameGlobals.pluscode_changed.connect(on_pluscode_changed)
	$scroll/vbox/MainHeader/btnViewMap.pressed.connect(ShowMapTile)
	$scroll/vbox/MainHeader/btnOptions.pressed.connect(ShowOptions)
	$scroll/vbox/MainHeader/btnScanExplorer.pressed.connect(ShowScanExplorer)
	$scroll/vbox/MainHeader/btnHelp.pressed.connect(ShowHelp)
	
	#Unused in the prototype
	Dialogic.VAR.captainName = GameGlobals.gameData.captainName
	Dialogic.VAR.shipName = GameGlobals.gameData.shipName
	
	#Force the first story/tutorial dialog to appear on first start.
	if (GameGlobals.gameData.plotProgress == -1):
		$scroll/vbox/OrdersScene.CompleteOrder()

func on_pluscode_changed(currentPlusCode, previousPlusCode):
	$scroll/vbox/MainHeader/lblCoords.text = currentPlusCode
	var fileExists = FileAccess.file_exists("user://NameTiles/" + currentPlusCode.substr(0,6) + ".png")
	if (fileExists == false):
		await $MinOfflineData.GetAndProcessData(currentPlusCode.substr(0,6))
		
	var currentPlace = GameGlobals.currentPlaceName
	var placeData = $PlaceTracker.CheckForPlace(currentPlusCode)
	
	if (placeData[0] != currentPlace):
		GameGlobals.currentPlaceName = placeData[0]
		$scroll/vbox/MainHeader/lblPlace.text = placeData[0]
		place_changed.emit(placeData[0])
		
	pluscode_changed.emit(currentPlusCode, previousPlusCode)

func on_place_changed(newPlace):
	$scroll/vbox/MainHeader/lblPlace.text = newPlace

func ShowScanExplorer():
	print("showing Scan Explorer")
	var PLse = preload("res://Scenes/ScanExplorer.tscn")
	var se =PLse.instantiate()
	se.position.y = 000
	add_child(se)

func ShowOptions():
	print("showing Options")
	var PLopt = preload("res://Scenes/Options/Options.tscn")
	var opt =PLopt.instantiate()
	opt.position.y = 600
	add_child(opt)
	
func ShowHelp():
	Dialogic.start("HelpMenu")

func ShowMapTile():
	print("showing map tile")
	var PLarea = preload("res://Scenes/AreaMap.tscn")
	var area =PLarea.instantiate()
	area.position.y = 800
	add_child(area)
	
func ShowPatrolMapTile():
	print("showing patrol map tile")
	var PLpatrol = preload("res://Scenes/PatrolMap.tscn")
	var patrol =  PLpatrol.instantiate()
	patrol.position.y = 600
	add_child(patrol)
	
func ShowStory(part):
	Dialogic.start(part)
