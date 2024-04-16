extends Node2D

func perm_check(permName, wasGranted):
	if permName == "android.permission.ACCESS_FINE_LOCATION" and wasGranted == true:
		$lblGranted.visible = true
		$btnStart.visible = true
		$btnGrant.visible = false

func GrantPermission():
	var granted = OS.request_permissions()
	if granted == true:
		perm_check("android.permission.ACCESS_FINE_LOCATION", true)
	
func StartGame():
	GameGlobals.gameData.skipLanding = true
	GameGlobals.SaveGame()
		
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")

func _ready():
	if GameGlobals.gameData.has("skipLanding") and GameGlobals.gameData.skipLanding == true:
		get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")

	get_tree().on_request_permissions_result.connect(perm_check)

func link_clicked(link):
	OS.shell_open(str(link))
