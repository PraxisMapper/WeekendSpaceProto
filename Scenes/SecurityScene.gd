extends Node2D

var lastCell8 = ""

func UpdateTotal(_cur, _old):
	$lblCellsPatrolled.text = str(GameGlobals.cellTracker.visited.size())
	
	if _cur == null:
		return
		
	var currentCell8 = _cur.substr(0,8)
	if FileAccess.file_exists("user://MapTiles/" + currentCell8 + ".png"):
		$PatrolMap2.visible = true
		$PatrolMap.visible = false
		$LogoPadding.visible = false
		$btnLoadData.visible = false
	else:
		$PatrolMap2.visible = false
		$PatrolMap.visible = true
		$LogoPadding.visible = true
		if GameGlobals.gameData.sideQuestsComplete.find("FixScanner") > -1 or GameGlobals.debug == true:
			$btnLoadData.visible = true

func _ready():
	GameGlobals.pluscode_changed.connect(UpdateTotal)
	UpdateTotal(null, null)

func LoadScanData():
	get_tree().change_scene_to_file("res://Scenes/FixScannerCutscene.tscn")
	#Return to the cutscene to load data for this Cell6
