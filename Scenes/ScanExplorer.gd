extends Node2D

func _ready():
	PraxisCore.plusCode_changed.connect(UpdateDisplay)
	UpdateDisplay(PraxisMapper.currentPlusCode, "")

func UpdateDisplay(cur, _old):
	$lblArea.text = cur.substr(0,6)
	
func Close():
	queue_free()

func GetAreaInfo():
	var requirements = ""
	var terrainID = $optTypes.get_item_id($optTypes.selected)
	
	if $chkFar.button_pressed:
		requirements += "far"
	if $chkSub.button_pressed:
		requirements += "sub"
		
	if $chkVisited.button_pressed:
		GameGlobals.placeTracker.Clear()

	var fixedDist = 0
	if $optDist.selected != 0:
		fixedDist = $optDist.get_item_id($optDist.selected)
	var places = $AreaScanner.ScanForPlaces(PraxisMapper.currentPlusCode.substr(0,6), terrainID, requirements, fixedDist)
	if $chkVisited.button_pressed:
		GameGlobals.placeTracker.Load()

	if places == null:
		$SC/VBOX/lblResults.text = "No Places Found"
		$lblCounts.text = "No Places Found"
		return
	
	var names = ""
	var results = "Results:\n"
	results += "Places Found: " + str(places.size()) + "\n\n"
	
	var countDict = {}
	for place in places:
		if countDict.has(place.tid):
			countDict[place.tid] += 1
		else:
			countDict[place.tid] = 1
		if place.has("name"):
			var type = GameGlobals.styleData[str(place.tid)].name
			var display = "[b]" + place.name + "[/b] [" + type + ", " + place.area + "]\n"
			if !names.contains("[b]" + place.name + "[/b] [" + type): #dont show both halves of a trail
				names += display

	var counts = "Place Counts:\r\n"
	for count in countDict.keys():
		counts += GameGlobals.styleData[str(count)].name + ": " + str(countDict[count]) + "\r\n"
	$lblCounts.text = counts
	
	results += names
	$SC/VBOX/lblResults.text = results

#Handles back button to close this window
func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()
