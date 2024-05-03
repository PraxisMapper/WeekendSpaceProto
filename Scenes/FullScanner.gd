extends Node2D


#This is the chunk of the screen for the Full scanner.
#It'll show that its in a damage state and glitch out slighlty in idle
#until you complete the side-quest to get full map data. Once that happens, 
#it'll show Cell8 tiles with full detail.

#TODO: I will also need a new scene to show the download and processing of data

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	#Need to check save game data, and be able to flip this in-game
	if GameGlobals.gameData.sideQuestsComplete.has("FixScanner"):
		ScannerFixed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func ScannerFixed():
	$Broken.visible = false
	$Fixed.visible = true
