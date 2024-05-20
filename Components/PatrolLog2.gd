extends Node2D

#cellTracker is 20x20, mapTile is 320x500


var lastPlusCode = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	
	GameGlobals.pluscode_changed.connect(plusCodeChanged)
	plusCodeChanged(PraxisCore.currentPlusCode, "")
	$cellTracker.scale = Vector2(16, 25)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func plusCodeChanged(cur, _old):
	$cellTracker.DrawCellTracker(GameGlobals.cellTracker, cur.substr(0,8))
	
	if _old == null or cur.substr(0,8) != _old.substr(0,8):
		$trMapTile.texture = await PraxisCore.GetCell8Tile(cur.substr(0,8))
