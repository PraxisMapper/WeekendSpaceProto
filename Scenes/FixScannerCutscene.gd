extends Node2D

#This is the scene for downloading and processing full map data.
#The new character should talk here the first time at points.
#I want a picture of the Cell6 minimium map in the scanner at first, and a bunch
#of gauges and dials and indicators that go from slow/blue-green to fast-red
#over steps. 

#Area for images is 960x1500

#TODO: this seems to have drawn some tiles with black areas that shouldn't be?
#was done in the spot north of the current test area. Why? Was that somehow correct?


#Alternative idea for this scene:
#A button to it is always present on the main screen (maybe in patrol log?)
#going to it bring you here, and we kick off the first cutscene and start the side quest
#with the "visit a library" objective, then run the chain from there instead of
#waiting 2 missions to kick it off. 
#This mostly resolves the UI issue of where to display side quests, which is
#fine if I'm only doing 1 of them for a prototype.
#for this, dont pick 'specific library'. pick 'Any library' and show distance to closest one.



# Called when the node enters the scene tree for the first time.
func _ready():
	
	#FlipToThumbnail() #testing the last part.
	
	SetBusyGauges()
	$GetFile.file_downloaded.connect(MakeTiles)
	$OfflineData.tile_created.connect(ShowEachTile)
	Start()
	#SetIdleGauges()
	#await get_tree().create_timer(3).timeout
	#print("gauges up")
	#SetBusyGauges()
	#await get_tree().create_timer(3).timeout
	#print("gauges up 2")
	#SetHighGauges()
	#await get_tree().create_timer(3).timeout
	#print("gauges up 3")
	#SetStressedConsole()
	#await get_tree().create_timer(3).timeout
	#print("gauges down")
	#SetIdleGauges()

func Start():
	var tex1 = ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + PraxisCore.currentPlusCode.substr(0,6) + ".png"))
	$MinDataOverlay/TextureRect.texture = tex1
	$MinDataOverlay/TextureRect.scale = Vector2(2.1, 3.45) #fill the square new data will be in
	
	$FullDataOverlay/TextureRect.scale = Vector2(2.65, 2.75)
	#TODO: show first cutscene, when over call this
	SetHighGauges()
	$GetFile.getFile(PraxisCore.currentPlusCode.substr(0,4))
	
	
	#TODO: resume cutscene.
	
	#Final bit of cutscene

func MakeTiles():
	SetStressedConsole()
	await $OfflineData.GetAndProcessData(PraxisCore.currentPlusCode.substr(0,6))
	FlipToThumbnail()
	
func ShowEachTile(newTile):
	$FullDataOverlay/TextureRect.texture = newTile #ImageTexture.create_from_image(newTile)
	

func FlipToThumbnail():
	var tex2 = ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + PraxisCore.currentPlusCode.substr(0,6) + "-thumb.png"))
	$FullDataOverlay/TextureRect.texture = tex2
	$FullDataOverlay/TextureRect.scale = Vector2(1.65, 1.71) #is now 512x800
	SetIdleGauges()

func SetIdleGauges():
	$Gauge.SetVals(.7, -65, 2)
	$Gauge2.SetVals(.7, -65, 2)
	$Gauge3.SetVals(.7, -65, 2)

func SetBusyGauges():
	$Gauge.SetVals(.4, -20, 1)
	$Gauge2.SetVals(.4, -20, 1)
	$Gauge3.SetVals(.4, -20, 1)

func SetHighGauges():
	$Gauge.SetVals(.2, 25, 0.5)
	$Gauge2.SetVals(.2, 25, 0.5)
	$Gauge3.SetVals(.2, 25, 0.5)
	
func SetStressedConsole():
	$Gauge.SetVals(.1, 65, 0.1)
	$Gauge2.SetVals(.1, 65, 0.1)
	$Gauge3.SetVals(.1, 65, 0.1)

func ExitScanner():
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
