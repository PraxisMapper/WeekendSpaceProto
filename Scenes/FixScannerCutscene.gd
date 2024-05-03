extends Node2D

#This is the scene for downloading and processing full map data.
#The new character should talk here the first time at points.
#I want a picture of the Cell6 minimium map in the scanner at first, and a bunch
#of gauges and dials and indicators that go from slow/blue-green to fast-red
#over steps. 

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Start()
	SetIdleGauges()
	await get_tree().create_timer(3).timeout
	print("gauges up")
	SetBusyGauges()
	await get_tree().create_timer(3).timeout
	print("gauges up 2")
	SetHighGauges()
	await get_tree().create_timer(3).timeout
	print("gauges up 3")
	SetStressedConsole()
	await get_tree().create_timer(3).timeout
	print("gauges down")
	SetIdleGauges()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func Start():
	$GetFile.getFile(PraxisCore.currentPlusCode.substr(0,4))

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
