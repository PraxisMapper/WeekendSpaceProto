extends Node2D

func _ready():
	#set display option from game globals
	$chkArtsCulture.button_pressed = GameGlobals.gameOptions.suggestArtsCulture
	$chkCemetery.button_pressed = GameGlobals.gameOptions.suggestCemeteries
	$chkHistorical.button_pressed = GameGlobals.gameOptions.suggestHistorical
	$chkNatureReserve.button_pressed = GameGlobals.gameOptions.suggestNatureReserves
	$chkPark.button_pressed = GameGlobals.gameOptions.suggestParks
	$chkUniversity.button_pressed = GameGlobals.gameOptions.suggestUniversities
	
func UpdateArtsCulture(newState):
	GameGlobals.gameOptions.suggestArtsCulture = newState
	GameGlobals.SaveGame()

func UpdateCemetery(newState):
	GameGlobals.gameOptions.suggestCemeteries = newState
	GameGlobals.SaveGame()

func UpdateHistorical(newState):
	GameGlobals.gameOptions.suggestHistorical = newState
	GameGlobals.SaveGame()
	
func UpdateNatureReserve(newState):
	GameGlobals.gameOptions.suggestNatureReserves = newState
	GameGlobals.SaveGame()

func UpdatePark(newState):
	GameGlobals.gameOptions.suggestParks = newState
	GameGlobals.SaveGame()

func UpdateUniversity(newState):
	GameGlobals.gameOptions.suggestUniversities = newState
	GameGlobals.SaveGame()

func UpdateBatterySaver(newState):
	GameGlobals.gameData.batterySaver = newState
	if newState == true:
		Engine.max_fps = 30
	else:
		Engine.max_fps = 60

func Close():
	queue_free()
