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

var defaultServerUrl = "https://global.praxismapper.org/Content/OfflineData/"

var sideQuests = {
	FixScanner = {
		start = {requirement = "MainQuest:2", storyName = "FixScanner1"},
		steps = [
			#After Story 2 is complete, run the FixScanner1 story
			#On arrival at a library, play FixScanner2
			{requirement = "place:library", storyName = "FixScanner2"},
			{requirement = "wait:library:5", storyName = "FixScanner2"},
			#on arrival at a graveyard, play FixScanner3
			{requirement = "place:graveyard", storyName = "FixScanner3"},
			#Wait 5 minutes at a graveyard, then run the fixing cutscene.
			{requirement = "wait:graveyard:5", storyName = "FixScanner4"},
		]
	}
}

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
	saveDataVersion = 2, #for updating save game format.
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
	sideQuestsInProgress = {}, #TODO: potential nonlinear mission structure.
	sideQuestsComplete = [], #just names
	serverUrl = defaultServerUrl
	
	#key is quest name/id, values are progressSteps. 
}

func _ready():
	LoadOptions()
	LoadGame()
	LoadIgnoreList()
	
	styleData = PraxisCore.GetStyle("suggestedmini")
	
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
		await PraxisCore.MakeMinimizedOfflineTiles(filename) #Works, because this adds node to the current tree.
	
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
		
		#check save version and apply updates by version difference when there are any.
		if gameData.saveDataVersion <= 1: #Load from Prototype B.
			gameData.sideQuestProgress = {}
			gameData.sideQuestsComplete = []
			gameData.saveDataVersion = 2
			gameData.serverUrl = defaultServerUrl
			SaveGame()

func UpdateSideQuests(current):
	#first check if any side quests are eligible to start
	for quest in sideQuests:
		if gameData.sideQuestsComplete.find(quest) > -1:
			continue
		
		#check the start requirements
		#TODO: multiple requirements? or chain quests?
		var req = quest.start.requirement
		if req.begins_with("MainQuest"):
			pass
			#this doesnt show up until you've gotten so far in the main quest.
	
	#for each active side quest, check what their progress requirement is
	#and if its complete, fire up the next step of that side quest (dialogic)
	#Also, for each side quest not started or in-progress, see if we can start it.
	
func ChangeToFixingScene():
	#This is called by Dialogic to move us to the scene for fixing the scanner.
	get_tree().change_scene_to_file("res://Scenes/FixScannerCutscene.tscn")

func DoStuffFromDialogic(actualCall, infoString):
	#Dialogic needs to call an Autoload to run Godot code,
	#so this function handles calling whatever is going on in the scene itself.
	if actualCall == "changeGauges1":
		#FixScannerCutscene.SetIdleGauges() ?
		pass
	if actualCall == "ReturnToMain":
		get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
		#Remove the bottom node from the main tree
		#get_tree().queue_delete()
		
