extends Node2D

#Patrol map handles the CellTracker data, and draws it to a screen to give you an idea where you've 
#been or not been before.

func Draw(_current, _new):
	var center = PraxisMapper.currentPlusCode.substr(0,8)
	$CellTrackerDrawer.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, -1, 1))
	$CellTrackerDrawer2.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, 0, 1))
	$CellTrackerDrawer3.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, 1, 1))
	$CellTrackerDrawer4.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, -1, 0))
	$CellTrackerDrawer5.DrawCellTracker(GameGlobals.cellTracker, center)
	$CellTrackerDrawer6.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, 1, 0))
	$CellTrackerDrawer7.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, -1, -1))
	$CellTrackerDrawer8.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, 0, -1))
	$CellTrackerDrawer9.DrawCellTracker(GameGlobals.cellTracker, PlusCodes.ShiftCode(center, 1, -1))

func Close():
	queue_free()

func _ready():
	Draw(null, null)
	GameGlobals.pluscode_changed.connect(Draw)
