extends Node2D

#Copied from default ScanExplorer and adjusted for full detailed data.
func _ready():
	PraxisCore.plusCode_changed.connect(UpdateDisplay)
	UpdateDisplay(PraxisCore.currentPlusCode, "")
	
	#loading this list from the data instead of hardcoding it
	
	var style = PraxisCore.GetStyle("mapTiles")
	#var typeList = []
	var entries = []
	entries.push_back({name = "All", id = 0})
	for type in style.keys():
		#typeList.push_back(style[types].name)
		entries.push_back({name = style[type].name, id = int(type)})
		#$optTypes.add_item(style[type].name, int(type))
	entries.sort_custom(func(a,b): return a.name < b.name )
	for entry in entries:
		$optTypes.add_item(entry.name, entry.id)
	
	
func UpdateDisplay(cur, _old):
	$lblArea.text = cur.substr(0,6)
	
func Close():
	#queue_free()
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")

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
	
	#TODO: this is much slower, so this should probably throw up a spinner
	#Or use a thread like the OrdersPanel does.
	var places = await $FullAreaScanner.ScanForPlaces(PraxisCore.currentPlusCode.substr(0,6), "mapTiles", terrainID, requirements, fixedDist)
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
		#We get the name of the terrain from the search on this one.
		if countDict.has(place.type):
			countDict[place.type] += 1
		else:
			countDict[place.type] = 1
		if place.has("name"):
			var display = "[b]" + place.name + "[/b] [" + place.type + ", " + place.area + "]\n"
			#OK, since this has retail entries, we'll allow dupes on the list.
			if $chkDupes.button_pressed or !names.contains("[b]" + place.name + "[/b] [" + place.type):
				names += display

	var counts = "Place Counts:\r\n"
	for count in countDict.keys():
		counts += count + ": " + str(countDict[count]) + "\r\n"
	$lblCounts.text = counts
	
	results += names
	$SC/VBOX/lblResults.text = results

#Handles back button to close this window
func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()

func SwitchToMin():
	get_tree().change_scene_to_file("res://Scenes/ScanExplorer.tscn")
