extends Node2D

var thread = Thread.new()

var orderArray = [
	"Patrol_125", #approximately a mile. #Story1
	"NewPlace", #Story2 
	"WaitPlace", #Story3
	"Patrol_375", # 3 miles worth of walking. Was 5, reduced for prototype. Story 4
	"NewPlace_sub", #Story 5
	"NewPlace_far", #Story 6
	"WaitPlace", #story 7
	"NewPlace_11", #Story8
	"FreePlay" #Story 9, ends prototype #May remove this, so the game has a proper ending
]
func UpdateScreen(_cur, _old):
	if (!GameGlobals.gameData.currentOrder.has("complete")):
		GetOrder() #this causes the first order to get filled in.

	if IsOrderComplete():
		GameGlobals.gameData.currentOrder.complete = true
	#now set some display values here.
	var isPlaceMission = GameGlobals.gameData.currentOrder.type.begins_with("NewPlace") or GameGlobals.gameData.currentOrder.type.begins_with("FreePlay")
	var showTargetDest = GameGlobals.gameData.currentOrder.type.begins_with("NewPlace") or GameGlobals.gameData.currentOrder.type.begins_with("WaitPlace")  or GameGlobals.gameData.currentOrder.type.begins_with("FreePlay")
	$lblOrders.text = GameGlobals.gameData.currentOrder.text
	if GameGlobals.gameData.currentOrder.place.has("area"):
		$lblTargetSector.text = GameGlobals.gameData.currentOrder.place.area
		$lblDistance.text = GetDistAndDirection(PraxisCore.currentPlusCode, GameGlobals.gameData.currentOrder.place.area)
	$lblTSHeader.visible = showTargetDest
	$lblDistHeader.visible = showTargetDest
	$lblTargetSector.visible = showTargetDest
	$lblDistance.visible = showTargetDest

	$btnCompleteOrder.visible = GameGlobals.gameData.currentOrder.complete
	$btnAddToIgnore.visible = isPlaceMission and !GameGlobals.gameData.currentOrder.complete
	$btnPickNew.visible = isPlaceMission and !GameGlobals.gameData.currentOrder.complete
	$btnNudge.visible = isPlaceMission and !GameGlobals.gameData.currentOrder.complete

func ChangePlace():
	if thread.is_alive():
		return
	thread.wait_to_finish()
	
	$lblOrders.text = "Scanning...."
	await RenderingServer.frame_post_draw
	var orderParts = GameGlobals.gameData.currentOrder.type.split("_")
	var condition = ""
	if orderParts.size() > 1:
		condition = orderParts[1]
	if (orderParts[0] == "FreePlay" and randi() % 4 == 0):
		condition = "far"
	var terrainType = int(condition)
	var newPlace = {}
	if FileAccess.file_exists("user://Data/Full/" + PraxisCore.currentPlusCode.substr(0,4) + ".zip"):
		#The type Ids vary between style sets. In a not-prototype game, there should be
		#some elegant way to handle this. Here, I'm gonna roll dice and use ifs.
		var fullTerrainType = 0
		var randomTerrainTypes = [20, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 500, 1000, 1200, 1300, 1400, 1500]
		if terrainType == 1:
			fullTerrainType = 1000
		elif terrainType == 2:
			fullTerrainType = 20
		elif terrainType == 3:
			fullTerrainType = 1200
		elif terrainType == 4:
			fullTerrainType = 1300
		elif terrainType == 5:
			fullTerrainType = 500
		elif terrainType == 6:
			fullTerrainType = 40
		elif terrainType == 7:
			fullTerrainType = 50
		elif terrainType == 8:
			fullTerrainType = 60
		elif terrainType == 9:
			fullTerrainType = 70
		elif terrainType == 10:
			fullTerrainType = 80
		elif terrainType == 11:
			fullTerrainType = 90
		elif terrainType == 12:
			fullTerrainType = 100
		elif terrainType == 13:
			fullTerrainType = 110
		elif terrainType == 14:
			fullTerrainType = 120
		elif terrainType == 15:
			fullTerrainType = 130
		elif terrainType == 16:
			fullTerrainType = 140
		elif terrainType == 17:
			fullTerrainType = 150
		elif terrainType == 18:
			fullTerrainType = 160
		elif terrainType == 19:
			fullTerrainType = 170
		elif terrainType == 20:
			fullTerrainType = 180
		elif terrainType == 21:
			fullTerrainType = 190
		elif terrainType == 22:
			fullTerrainType = 200
		elif terrainType == 23:
			fullTerrainType = 210
		elif terrainType == 24:
			fullTerrainType = 220
		elif terrainType == 25:
			fullTerrainType = 1500
		
		terrainId = fullTerrainType
		reqs = condition
		thread.start(scanOnThread)
		return
	else:
		newPlace = await $AreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), terrainType, condition)
	if newPlace == null:
		return
	
	var oldPlace = GameGlobals.gameData.currentOrder.place.name
	GameGlobals.gameData.currentOrder.place = newPlace
	if orderParts[0] == "FreePlay":
		GameGlobals.gameData.currentOrder.text = "Explore the world at your whim. Consider a trip to " + newPlace.name
	else:
		GameGlobals.gameData.currentOrder.text = "Make an expedition to " + newPlace.name
	if newPlace.has("parentName"):
		GameGlobals.gameData.currentOrder.text += " in or near " + newPlace.parentName
	GameGlobals.SaveGame()
	
	UpdateScreen(null, null)
	


signal scan_done()

var terrainId = 0
var reqs = ""
var placePicked = null
func scanOnThread():
	var scanner = FullAreaScanner.new()
	placePicked = null
	var randomTerrainTypes = [20, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 500, 1000, 1200, 1300, 1400, 1500]
	if terrainId != 0:
		randomTerrainTypes = [terrainId]
	while placePicked == null and randomTerrainTypes.size() > 0:
		var scanThisType = randomTerrainTypes.pop_at(randi_range(0, randomTerrainTypes.size() - 1))
		placePicked = await scanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), "mapTiles", scanThisType, reqs)
	
	call_deferred("emit_signal", "scan_done")
	
func fullScanDone():
	var orderParts = GameGlobals.gameData.currentOrder.type.split("_")
	var oldPlace = GameGlobals.gameData.currentOrder.place.name
	var newPlace = placePicked
	if placePicked == null:
		$lblOrders.text = "No valid place found. Move somewhere else and try again"
		return
	
	GameGlobals.gameData.currentOrder.place = newPlace
	if orderParts[0] == "FreePlay":
		GameGlobals.gameData.currentOrder.text = "Explore the world at your whim. Consider a trip to " + newPlace.name
	else:
		GameGlobals.gameData.currentOrder.text = "Make an expedition to " + newPlace.name
	if newPlace.has("parentName"):
		GameGlobals.gameData.currentOrder.text += " in or near " + newPlace.parentName
	GameGlobals.SaveGame()
	
	UpdateScreen(null, null)
	

func _ready():
	UpdateScreen(null, null)
	GameGlobals.pluscode_changed.connect(UpdateScreen)
	scan_done.connect(fullScanDone)
	if (GameGlobals.debug):
		$btnDebugAdvance.visible = true

func CompleteOrder():
	#the button to complete the current order has been pressed
	$btnCompleteOrder.visible = false
	GameGlobals.gameData.plotProgress += 1
	var advance = GetOrder()
	UpdateScreen(null, null)
	
	if advance == false:
		return
	#Update Dialogic variables, show plot. Not all of these are used
	#in the prototype
	Dialogic.VAR.missionPlace = GameGlobals.gameData.currentOrder.place.name
	if GameGlobals.gameData.currentOrder.place.has("parentName"):
		Dialogic.VAR.parentPlace = GameGlobals.gameData.currentOrder.place.parentName
	else:
		Dialogic.VAR.parentPlace = ""
	Dialogic.VAR.totalSectorCount100 = floor(GameGlobals.cellTracker.visited.size() / 100)
	Dialogic.VAR.totalSectorCountStr = str(GameGlobals.cellTracker.visited.size())
	if GameGlobals.gameData.currentOrder.place.has("area"):
		Dialogic.VAR.missionPlusCode = GameGlobals.gameData.currentOrder.place.area
	else:
		Dialogic.VAR.missionPlusCode = ""
	GameGlobals.SaveGame()
	
	var storyName = "Story" + str(GameGlobals.gameData.plotProgress + 1)
	Dialogic.start(storyName)
	
func GetOrder():
	var order = {
		place = {
			name = "",
			parentName = "",
			area = ""
		}
	}
	if GameGlobals.gameData.plotProgress >= orderArray.size():
		GameGlobals.gameData.plotProgress = orderArray.size() - 1
	var nextOrderType = orderArray[GameGlobals.gameData.plotProgress]
	order.type = nextOrderType
	order.complete = false
	
	if nextOrderType == "FreePlay":
		order.text = "Explore the world at your whim. Consider a trip to "
		order.text += order.place.name
		if order.place.parentName != "":
			order.text += " at or near " + order.place.parentName
	elif nextOrderType == "WaitPlace":
		order.place = GameGlobals.gameData.currentOrder.place
		order.text = "Explore " + order.place.name + " for 15 minutes"
		order.endTime = Time.get_unix_time_from_system() + (15 * 60)
	elif nextOrderType == "Promotion":
		order.text = "Apply for your Promotion to Admiral at your Home Base"
	elif nextOrderType == "HomeBase":
		order.text = "Return to Home Base."
	elif nextOrderType.begins_with("NewPlace"):
		var parts = nextOrderType.split("_") #2nd part indicates special conditions
		if (parts.size() == 1):
			parts.append("")
		order.newPlaceVisited = false
		var terrainType = int(parts[1]) #parts[1] can be a number or a string.
		
		var place = {}
		if FileAccess.file_exists("user://Data/Full/" + PraxisCore.currentPlusCode.substr(0,4) + ".zip"):
			#The type Ids vary between style sets. In a not-prototype game, there should be
			#some elegant way to handle this. Here, I'm gonna roll dice and use ifs.
			var fullTerrainType = 0
			var randomTerrainTypes = [20, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 500, 1000, 1200, 1300, 1400, 1500]
			if terrainType == 0:
				fullTerrainType = randomTerrainTypes.pick_random()
			elif terrainType == 1:
				fullTerrainType = 1000
			elif terrainType == 2:
				fullTerrainType = 20
			elif terrainType == 3:
				fullTerrainType = 1200
			elif terrainType == 4:
				fullTerrainType = 1300
			elif terrainType == 5:
				fullTerrainType = 500
			elif terrainType == 6:
				fullTerrainType = 40
			elif terrainType == 7:
				fullTerrainType = 50
			elif terrainType == 8:
				fullTerrainType = 60
			elif terrainType == 9:
				fullTerrainType = 70
			elif terrainType == 10:
				fullTerrainType = 80
			elif terrainType == 11:
				fullTerrainType = 90
			elif terrainType == 12:
				fullTerrainType = 100
			elif terrainType == 13:
				fullTerrainType = 110
			elif terrainType == 14:
				fullTerrainType = 120
			elif terrainType == 15:
				fullTerrainType = 130
			elif terrainType == 16:
				fullTerrainType = 140
			elif terrainType == 17:
				fullTerrainType = 150
			elif terrainType == 18:
				fullTerrainType = 160
			elif terrainType == 19:
				fullTerrainType = 170
			elif terrainType == 20:
				fullTerrainType = 180
			elif terrainType == 21:
				fullTerrainType = 190
			elif terrainType == 22:
				fullTerrainType = 200
			elif terrainType == 23:
				fullTerrainType = 210
			elif terrainType == 24:
				fullTerrainType = 220
			elif terrainType == 25:
				fullTerrainType = 1500
			place = $FullAreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), "mapTiles", fullTerrainType, parts[1])
			while place == null and terrainType == 0 and randomTerrainTypes.size() > 0:
				fullTerrainType = randomTerrainTypes.pop_at(randi_range(0, randomTerrainTypes.size()))
				place = $FullAreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), "mapTiles", fullTerrainType, parts[1])
		else:
			place = $AreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), terrainType, parts[1])
		
		if place == null:
			print("No place found!") #PickPlace shows the error dialog.
			GameGlobals.gameData.plotProgress -= 1
			return false

		order.place = place
		if place.has("parentName"):
			order.text = "Make an expedition to " + place.name + ", inside or near " + place.parentName + "."
		else:
			order.text = "Make an expedition to " + place.name + "."
	elif nextOrderType.begins_with("Patrol"):
		#TODO: add a way to make a Patrol order be specifically "X new tiles", not just "X total tiles"
		var parts = nextOrderType.split("_")
		order.text = "Patrol " + parts[1] + " tiles of space."
		order.amount = int(parts[1])
	#Reamining options arent used in the prototype
	elif nextOrderType.begins_with("Wait"):
		var parts = nextOrderType.split("_")
		order.text = "Come back in " + parts[1] + " hours ."
		order.amount = int(parts[1])
		order.endTime = Time.get_unix_time_from_system() + (22 * 60 * 60)
	elif nextOrderType.begins_with("Science"):
		var parts = nextOrderType.split("_")
		order.text = "Accomplish a 1 in " + parts[1] + " Science breakthrough."
		order.amount = int(parts[1])
		
	GameGlobals.gameData.currentOrder = order
	return true

func IsOrderComplete():
	if GameGlobals.gameData.currentOrder.type == "FreePlay":
		return false
	elif GameGlobals.gameData.currentOrder.type == "WaitPlace":
		var timePassed = GameGlobals.gameData.currentOrder.endTime <= Time.get_unix_time_from_system()
		return timePassed and GameGlobals.currentPlaceName == GameGlobals.gameData.currentOrder.place.name
	elif GameGlobals.gameData.currentOrder.type == "Promotion":
		return GameGlobals.isAtHomeBase
	elif GameGlobals.gameData.currentOrder.type == "HomeBase":
		return GameGlobals.isAtHomeBase
	elif GameGlobals.gameData.currentOrder.type.begins_with("Patrol"):
		return GameGlobals.cellTracker.visited.size() > GameGlobals.gameData.currentOrder.amount
	elif GameGlobals.gameData.currentOrder.type.begins_with("Wait"):
		return GameGlobals.gameData.currentOrder.endTime <= Time.get_unix_time_from_system()
	elif GameGlobals.gameData.currentOrder.type.begins_with("NewPlace"):
		return GameGlobals.currentPlaceName == GameGlobals.gameData.currentOrder.place.name
	elif GameGlobals.gameData.currentOrder.type.begins_with("Science"):
		#this needs to wait until Science code is set up.
		return true
	return false
	
func GetDist(current, target):
	var point1 = PlusCodes.Decode(current)
	var point2 = PlusCodes.Decode(target)
	
	var a_sqared = (point1.x - point2.x) ** 2
	var b_sqared = (point1.y - point2.y) ** 2
	var c_squared = a_sqared + b_sqared
	var distance = sqrt(c_squared)
	return distance

func GetAngle(current, target):
	var point1 = PlusCodes.Decode(current)
	var point2 = PlusCodes.Decode(target)
	
	#This is pretty important, since negative numbers screw up the calculation.
	point1 += Vector2 (180, 90)
	point2 += Vector2 (180, 90)
	
	var anglePart1 = cos(point2.y) * sin(point1.x - point2.x)
	var anglePart2 = cos(point1.y) * sin(point2.y) - sin(point1.y) * cos(point2.y) * cos(point1.x - point2.x)
	var baseAngleRads = atan2(anglePart2, anglePart1) #makes 0 degress going East/right) and counter-clockwise
	var actualAngleDegs = rad_to_deg(baseAngleRads)
	return actualAngleDegs

func GetDistAndDirection(current, target):
	#Given where the player is standing, and where their target area is, work out
	#the distance between the 2, and a rough compass heading.
	var distance = GetDist(current, target)
	var actualAngleDegs = GetAngle(current,target)
	var direction = "?"
	
	if actualAngleDegs >= -22.5 and actualAngleDegs <= 22.5:
		direction = "East"
	elif actualAngleDegs >= 22.5 and actualAngleDegs <= 67.5:
		direction = "North-East"
	elif actualAngleDegs >= 67.5 and actualAngleDegs <= 112.5:
		direction = "North"
	elif actualAngleDegs >= 112.5 and actualAngleDegs <= 157.5:
		direction = "North-West"
	elif actualAngleDegs >= 157.5:
		direction = "West"
	elif actualAngleDegs <= -22.5 and actualAngleDegs >= -67.5:
		direction = "South-East"
	elif actualAngleDegs <= -67.5 and actualAngleDegs >= -112.5:
		direction = "South"
	elif actualAngleDegs <= -112.5 and actualAngleDegs >= -157.5:
		direction = "South-West"
	elif actualAngleDegs <= -157.5:
		direction = "West"

	return str(floor(distance / 0.000125)) + " sectors " + direction

func NudgeCheck():
	#Force the app to check all places and see if we're standing in the one our mission wants.
	#We do load the data and check always, because it could be just outside the current tile's bounds
	
	var dist = GetDist(PraxisCore.currentPlusCode, GameGlobals.gameData.currentOrder.place.area)
	if (dist <= (0.000625)): #Treat place as radius=5. This is meant for small places.
		print("nudged into the area, completeing order.")
		GameGlobals.gameData.currentOrder.complete = true
		UpdateScreen(null, null)

func IgnorePlace():
	var area = GameGlobals.gameData.currentOrder.place.area.substr(0,6)
	if !GameGlobals.ignoreList.has(area):
		GameGlobals.ignoreList[area] = []
	GameGlobals.ignoreList[area].push_back(GameGlobals.gameData.currentOrder.place.name)
	GameGlobals.SaveIgnoreList()
	ChangePlace()
