extends Node2D
#TODO?: make this read the full detailed data if its available, instead of
#only using minimized offline data. This might be enough to throw to a future project.
#KNOWN: this doesn't filter down to the gameplay viable places yet. I'll have to
#work out how to cherry-pick those and convert from suggestedMini values to 
#mapTiles values.

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
	print($lblOrders.text)
	print(GameGlobals.gameData.currentOrder.place.name)
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
	var orderParts = GameGlobals.gameData.currentOrder.type.split("_")
	var condition = ""
	if orderParts.size() > 1:
		condition = orderParts[1]
	if (orderParts[0] == "FreePlay" and randi() % 4 == 0):
		condition = "far"
	var terrainId = int(condition)
	var newPlace = {}
	if FileAccess.file_exists("user://Data/Full/" + PraxisCore.currentPlusCode.substr(0,4) + ".zip"):
		newPlace = $FullAreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), "mapTiles", terrainId, condition)
	else:
		newPlace = $AreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), terrainId, condition)
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

func _ready():
	UpdateScreen(null, null)
	GameGlobals.pluscode_changed.connect(UpdateScreen)
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
		var terrainType = int(parts[1])
		
		var place = {}
		if FileAccess.file_exists("user://Data/Full/" + PraxisCore.currentPlusCode.substr(0,4) + ".zip"):
			#TODO: make sure this works the same as the original. parts[1] might be different?
			place = $FullAreaScanner.PickPlace(PraxisCore.currentPlusCode.substr(0,6), "mapTiles", terrainType, parts[1])
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
		if GameGlobals.currentPlaceName != null:
			print("|" + GameGlobals.currentPlaceName + "| vs |" + GameGlobals.gameData.currentOrder.place.name + "|")
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
