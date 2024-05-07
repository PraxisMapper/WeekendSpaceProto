extends Node2D

var lastCell8 = ""

func UpdateTotal(_cur, _old):
	if _cur == null:
		return
	$lblCellsPatrolled.text = str(GameGlobals.cellTracker.visited.size())
	
	var currentCell8 = _cur.substr(0,8)
	if FileAccess.file_exists("user://MapTiles/" + currentCell8 + ".png"):
		if lastCell8 != currentCell8:
			$cell8Img.texture = ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + currentCell8 + ".png"))

func _ready():
	GameGlobals.pluscode_changed.connect(UpdateTotal)
	UpdateTotal(null, null)
