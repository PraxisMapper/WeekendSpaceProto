extends Node2D

#this control should show up when no GPS is available.
@onready var label : Label = $CanvasLayer/ColorRect/Label

func GoNorth():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, 0, 1))
	
func GoSouth():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, 0, -1))
	
func GoEast():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, 1, 0))
	
func GoWest():
	PraxisMapper.forceChange(PlusCodes.ShiftCode(PraxisMapper.currentPlusCode, -1, 0))

func _process(delta):
	label.text = PraxisMapper.currentPlusCode	
	if (Input.is_key_pressed(KEY_UP)):
		GoNorth()
	if (Input.is_key_pressed(KEY_DOWN)):
		GoSouth()
	if (Input.is_key_pressed(KEY_LEFT)):
		GoWest()
	if (Input.is_key_pressed(KEY_RIGHT)):
		GoEast()
