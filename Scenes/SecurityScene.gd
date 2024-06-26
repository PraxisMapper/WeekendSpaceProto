extends Node2D

var lastCell8 = ""

func UpdateTotal(_cur, _old):
	$lblCellsPatrolled.text = str(GameGlobals.cellTracker.visited.size())
	
	if _cur == null:
		return
		
	
	var currentCell8 = _cur.substr(0,8)
	if FileAccess.file_exists("user://Data/Full/" + currentCell8.substr(0,4) + ".zip"):
		$PatrolMap2.visible = true
		$PatrolMap.visible = false
		$LogoPadding.visible = false
		$btnLoadData.visible = false
		$lblAllPlaces.visible = true
		var placeText = "Places:\n"
		#Cell11 / 12 checking is a future task.
		var places = GameGlobals.placeTracker.GetDataOnPointFull(_cur.replace("+", "").substr(0,10)) 
		for place in places:
			placeText += place.split("|")[0] + "\n"
		$lblAllPlaces.text = placeText
	else:
		$PatrolMap2.visible = false
		$PatrolMap.visible = true
		$LogoPadding.visible = true
		$lblAllPlaces.visible = false
		#if GameGlobals.gameData.sideQuestsComplete.find("FixScanner") > -1 or GameGlobals.debug == true:
		#if GameGlobals.gameData.plotProgress >= 1:
		$btnLoadData.visible = true

func _ready():
	GameGlobals.pluscode_changed.connect(UpdateTotal)
	UpdateTotal(PraxisCore.currentPlusCode, null)
	
	#New plan is to just let you download data and draw each tile individually
func LoadData2():
	$GetFile.getFile(PraxisCore.currentPlusCode.substr(0,4))
	await $GetFile.file_downloaded
	$PatrolMap2.plusCodeChanged(PraxisCore.currentPlusCode, null) #draw this tile
	UpdateTotal(PraxisCore.currentPlusCode, null)

#The original plan was to have this scene generate each Cell8 in the Cell6
#at once. This doesn't work reliably in places with over 10k map elements though
func LoadScanData():
	get_tree().change_scene_to_file("res://Scenes/FixScannerCutscene.tscn")
	#Return to the cutscene to load data for this Cell6
