extends Node2D

func UpdateTotal(_cur, _old):
	$lblCellsPatrolled.text = str(GameGlobals.cellTracker.visited.size())

func _ready():
	GameGlobals.pluscode_changed.connect(UpdateTotal)
	UpdateTotal(null, null)
