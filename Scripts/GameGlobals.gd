extends Node

#For this game, I'll be checking data in the res://OfflineData folder.
#This is the super-minimized version, where it draws points by radius. 

var debug = true #set to false when shipping.
var placeTracker
var cellTracker
var currentPlaceName
var isAtHomeBase = false
var ignoreList = {}
var styleData = {}

#GameGlobals will intercept the core signals from PraxisMapper,
#do all of the required processing in order (Make name/terrain tiles, etc)
#and then fire off a signal that all of this game's components should listen to instead.
signal pluscode_changed(current, old)
signal location_changed(dictionary_vals)

var gameOptions = {
	suggestParks = true,
	suggestNatureReserves = true,
	suggestUniversities = true,
	suggestHistorical = true,
	suggestArtsCulture = true,
	suggestCemeteries = true,
}

#NOTE: a lot of these are here from planned full-game ideas, not prototype execution.
var gameData = {
	saveDataVersion = 1, #for updating save game format.
	skipLanding = false, #Set to true after reading the landing page.
	batterySaver = false,
	homeBase = "", #plusCode10, radius ~4?
	captainName = "",
	shipName = "",
	plotProgress = -1, #Our counter of completed story orders. Starts at -1 to indicate a new game.
	currentOrder = {
		place = {
			name = "",
			parentName = "",
			area = ""
		}
	}, #any additional data about the currently assigned order.
	queuedNewPlaces = {}, #if new places dont immediately fire off events, this is where they go to get handled.
	crew = {}, #name : crewData
	depts = {}, #might replace with ship model, since there will be 3 fixed ships.
	timePerTick = 4, #seconds
	totalTicks = 0,
	lastTick = 0, #unix system time
	baseSalary = 1, #can this be increased separately?
	awayMissions = [], #require the player to be in the place to end them
	remoteMissions = [], #these ones dont require you to be in the place to finish
}

func _ready():
	LoadOptions()
	LoadGame()
	LoadIgnoreList()
	
	styleData = PraxisMapper.GetStyle("suggestedmini")
	
	var placeTrackerpreload = preload("res://PraxisMapper/Scripts/PlaceTracker.tscn")
	placeTracker = placeTrackerpreload.instantiate()
	add_child(placeTracker)
	
	var cellTrackerpreload = preload("res://PraxisMapper/Controls/CellTracker.tscn")
	cellTracker = cellTrackerpreload.instantiate()
	add_child(cellTracker)
	
	PraxisCore.plusCode_changed.connect(PluscodeChanged)
	PraxisCore.location_changed.connect(LocationChanged)
	
func LocationChanged(dict):
	location_changed.emit(dict)

func PluscodeChanged(currentPlusCode, previousPlusCode):
	var filename = currentPlusCode.substr(0,6)
	var fileExists = FileAccess.file_exists("user://NameTiles/" + filename + ".png")
	if (fileExists == false): 
		PraxisCore.MakeMinOfflineTiles(filename) #Works, because this adds node to the current tree.
	
	cellTracker.Add(currentPlusCode)
	pluscode_changed.emit(currentPlusCode, previousPlusCode)

#Unused for the prototype
func NewCrew():
	var crew = {
		name = "",
		species = "",
		rank = "",
		missionsCompleted = 0,
		assignedSlot = 0,
		securityStat = 0,
		engineeringStat = 0,
		scienceStat = 0,
		bonus1 = "",
		bonus2 = "",
		bonus3 = "",
		recruitedAt = {
			name = "",
			plusCode = "",
			dateRecruited = 0 #unix system time
		},
		medals = {},
		
	}
	return crew

#Unused in the prototype
func NewMission():
	var mission = {
		placeName = "",
		timeStarted = 0.0, #unix time
		timeEnding = 0.0, #unix time
		crew = [],
	}
	
	return mission

func SaveOptions():
	var json = JSON.new()
	var optionString = json.stringify(gameOptions)
	var optionData = FileAccess.open("user://Data/Options.json", FileAccess.WRITE)
	if (optionData == null):
		print(FileAccess.get_open_error())
	
	optionData.store_string(optionString)
	optionData.close()

func LoadOptions():
	var localOptions = FileAccess.open("user://Data/Options.json", FileAccess.READ)
	if (localOptions == null):
		return
	else:
		var json = JSON.new()
		json.parse(localOptions.get_as_text())
		gameOptions = json.get_data()
		localOptions.close()
		
func LoadIgnoreList():
	var localIgnore = FileAccess.open("user://Data/Ignored.json", FileAccess.READ)
	if (localIgnore == null):
		return
	else:
		var json = JSON.new()
		json.parse(localIgnore.get_as_text())
		ignoreList = json.get_data()
		localIgnore.close()

#TODO: make 1 'SaveFile' function, and pass it filenames and dictionaries to save. Same for loads.
func SaveIgnoreList():
	var json = JSON.new()
	var dataString = json.stringify(ignoreList)
	var dataFile = FileAccess.open("user://Data/Ignored.json", FileAccess.WRITE)
	if (dataFile == null):
		print(FileAccess.get_open_error())
	
	dataFile.store_string(dataString)
	dataFile.close()

func SaveGame():
	var json = JSON.new()
	var dataString = json.stringify(gameData)
	var dataFile = FileAccess.open("user://Data/GameData.json", FileAccess.WRITE)
	if (dataFile == null):
		print(FileAccess.get_open_error())
	
	dataFile.store_string(dataString)
	dataFile.close()
	
func LoadGame():
	var localGameData = FileAccess.open("user://Data/GameData.json", FileAccess.READ)
	if (localGameData == null):
		return
	else:
		var json = JSON.new()
		json.parse(localGameData.get_as_text())
		gameData = json.get_data()
		localGameData.close()
		
		#apply settings
		if gameData.batterySaver == true:
			Engine.max_fps = 30
		
		#TODO: check save version and apply fixed by version difference when there are any.

#TODO: make an offline static class for this stuff so i quit copying it around so much
#The GameGlobals version should be the only one called here (PM Core compoments may have 
#its own separate entry to backport)
func GetDataFromZip(plusCode):
	#Godot checks all files in the assets folder for something, so to cut down on
	#the file count at startup we use ~200 zip files each holding ~200 zip files.
	#So first, check if the code4 zip exists. If not, ppull it from the code2 zip.
	#Then read the code4 zip and pull out the actual code6 data
	var code2 = plusCode.substr(0, 2)
	var code4 = plusCode.substr(2, 2)        
	
	if !FileAccess.file_exists("user://Data/" + code2 + code4 + ".zip"):
		var zipReaderA = ZIPReader.new()
		var err = zipReaderA.open("res://OfflineData/" + code2 + ".zip")
		if (err != OK):
			print("Read Error on " + code2 + ".zip: " + error_string(err))
			return null
		
		var innerFile = zipReaderA.read_file(code2 + code4 + ".zip")
		var destFile = FileAccess.open("user://Data/" + code2 + code4 + ".zip", FileAccess.WRITE)
		destFile.store_buffer(innerFile)
		destFile.close()
	
	var zipReaderB = ZIPReader.new()
	var err = zipReaderB.open("user://Data/" + code2 + code4 + ".zip")
	if (err != OK):
		print("Read Error on " + code2 + code4 + ".zip: " + error_string(err))
		return null
		
	var rawdata := zipReaderB.read_file(plusCode + ".json")
	var realData = rawdata.get_string_from_utf8()
	var json = JSON.new()
	json.parse(realData)
	return json.data

func GetStyle(style):
	var styleData = FileAccess.open("res://PraxisMapper/Styles/" + style + ".json", FileAccess.READ)
	if (styleData == null):
		print("HEY DEV - go make and save the style json here!")
	else:
		var json = JSON.new()
		json.parse(styleData.get_as_text())
		return json.get_data()
