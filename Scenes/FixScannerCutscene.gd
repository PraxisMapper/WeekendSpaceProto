extends Node2D

#I had a plan set up for this to be a big deal and part of a side quest
#to unlock, but I eventually decided that its not particularly worth it.
#Keeping this here for future refernce on how to draw tiles in bulk.

var plusCode = ''

# Called when the node enters the scene tree for the first time.

func _ready():
	plusCode = PraxisCore.currentPlusCode #default behavior
	#plusCode = "8FW4V75W25" # force-testing certain locations (Paris)
	#FlipToThumbnail() #testing the last part.
	
	SetBusyGauges()
	$GetFile.file_downloaded.connect(MakeTiles)
	#$OfflineData.tile_created.connect(ShowEachTile)
	$FullSingleTile.tile_created.connect(ShowEachTile)
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
	var tex1 = ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + plusCode.substr(0,6) + ".png"))
	$MinDataOverlay/TextureRect.texture = tex1
	$MinDataOverlay/TextureRect.scale = Vector2(2.1, 3.45) #fill the square new data will be in
	
	$FullDataOverlay/TextureRect.texture = tex1
	$FullDataOverlay/TextureRect.scale = Vector2(2.65, 2.75)
	SetHighGauges()
	$GetFile.getFile(plusCode.substr(0,4))

func MakeTiles():
	SetStressedConsole()
	#looping through the code alphabet on each axis. It's the least rework.
	for x in PlusCodes.CODE_ALPHABET_:
		for y in PlusCodes.CODE_ALPHABET_:
			await $FullSingleTile.GetAndProcessData(plusCode.substr(0,6) + x + y)
			$lblBanner.text = "Processed " + plusCode.substr(0,6) + x + y
	
var calls = 0
func ShowEachTile(newTile):
	#$FullSingleTile.tile_created.disconnect(ShowEachTile)
	#if currentDispOverlay == $FullDataOverlay:
	#NOTE: when this was just the texture, that was live from the viewport. 
	#using the image here is static, and won't automatically update or blink.
	if calls == 0:
		$FullDataOverlay/TextureRect.texture.set_image(newTile) #ImageTexture.create_from_image(newTile)
	else:
		$FullDataOverlay/TextureRect.texture.update(newTile) #ImageTexture.create_from_image(newTile)

func FlipToThumbnail():
	var tex2 = ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + plusCode.substr(0,6) + "-thumb.png"))
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
