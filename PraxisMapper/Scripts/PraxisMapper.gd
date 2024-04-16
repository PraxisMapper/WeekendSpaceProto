extends Node
class_name PraxisMapper

#NOTE: PraxisMapper is the class name for static values.
#For the singleton instance in autoload, use PraxisCore

#config values referenced by components
static var mapTileWidth = 320
static var mapTileHeight = 500 #Local number, not server number
#This variable should exist for debugging purposes, but I've provided a few choices for convenience.
static var debugStartingPlusCode = "85633QG4VV" #Elysian Park, Los Angeles, CA, USA
#static var debugStartingPlusCode = "87G8Q2JMGF" #Central Park, New York City, NY, USA
#static var debugStartingPlusCode = "8FW4V75W25" #Eiffel Tower Garden, France
#static var debugStartingPlusCode = "9C3XGV349C" #The Green Park, London, UK
#static var debugStartingPlusCode = "8Q7XMQJ595" #Kokyo Kien National Garden, Tokyo, Japan
#static var debugStartingPlusCode = "8Q336FJCRV" #Peoples Park, Shanghai, China
#static var debugStartingPlusCode = "7JWVP5923M" #Shalimar Bagh, Delhi, India
#static var debugStartingPlusCode = "86FRXXXPM8" #Ohio State University, Columbus, OH, USA

#System global values
#Resolution of PlusCode cells in degrees
const resolutionCell12Lat = .000025 / 5
const resolutionCell12Lon = .00003125 / 4; 
const resolutionCell11Lat = .000025;
const resolutionCell11Lon = .00003125; 
const resolutionCell10 = .000125; 
const resolutionCell8 = .0025; 
const resolutionCell6 = .05; 
const resolutionCell4 = 1; 
const resolutionCell2 = 20;
const metersPerDegree = 111111
const oneMeterLat = 1 / metersPerDegree

#storage values for global access at any time.
static var currentPlusCode = '' #The Cell10 we are currently in.
static var lastPlusCode = '' #the previous Cell10 we visited.

#signals for components that need to respond to it.
signal plusCode_changed(current, previous)
signal location_changed(dictionary)

#support components
static var gps_provider


#Use this so that each client generates the same values for a specific pluscode
#Due to hash being a 32-bit int, this is only likely to be unique for 6-digit or shorter codes
#8-digit or longer codes are nearly guaranteed to have duplicates SOMEWHERE on the planet, but 
#probably not nearby.
static func GetFixedRNGForPluscode(pluscode):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(pluscode)
	return rng

static func forceChange(newCode):
	if newCode.find("+") == -1:
		newCode = newCode.substr(0,8) + "+" + newCode.substr(8)
	lastPlusCode = currentPlusCode
	currentPlusCode = newCode
	PraxisCore.plusCode_changed.emit(currentPlusCode, lastPlusCode)

func on_monitoring_location_result(location: Dictionary) -> void:
	location_changed.emit(location)
	print("location changed" + str(location))
	var plusCode = PlusCodes.EncodeLatLon(location["latitude"], location["longitude"])
	if (plusCode != currentPlusCode):
		lastPlusCode = currentPlusCode
		currentPlusCode = plusCode
		plusCode_changed.emit(currentPlusCode, lastPlusCode)
		
func perm_check(permName, wasGranted):
	print("permissions: " + permName)
	print(wasGranted)
	if permName == "android.permission.ACCESS_FINE_LOCATION" and wasGranted == true:
		print("enabling GPS")
		gps_provider.onLocationUpdates.connect(on_monitoring_location_result)
		gps_provider.StartListening()

func _ready():
	DirAccess.make_dir_absolute("user://MapTiles")
	DirAccess.make_dir_absolute("user://NameTiles")
	DirAccess.make_dir_absolute("user://BoundsTiles")
	DirAccess.make_dir_absolute("user://TerrainTiles")
	DirAccess.make_dir_absolute("user://Styles") #may be removed if these get baked in, or moved to res://
	DirAccess.make_dir_absolute("user://Offline")
	DirAccess.make_dir_absolute("user://Data") #used to store tracker data in JSON, rather than images.
	
	get_tree().on_request_permissions_result.connect(perm_check)
	
	gps_provider = await Engine.get_singleton("PraxisMapperGPSPlugin")
	if gps_provider != null:
		var perms = OS.get_granted_permissions() #Shouldn't ask for permissions here.
		if perms.find("android.permission.ACCESS_FINE_LOCATION") > -1:
			print("enabling GPS")
			gps_provider.onLocationUpdates.connect(on_monitoring_location_result)
			gps_provider.StartListening()
	else:
		print("GPS Provider not loaded (probably debugging on PC)")
		currentPlusCode = debugStartingPlusCode
		var debugControlScene = preload("res://PraxisMapper/Controls/DebugMovement.tscn")
		var debugControls = debugControlScene.instantiate()
		add_child(debugControls)
		debugControls.position.x = 0
		debugControls.position.y = 0
		debugControls.z_index = 200
		
static func GetDataFromZip(file, plusCode):
	var zipReader = ZIPReader.new()
	var err = zipReader.open("user://" + file) #Assumes this was written to the user partition, not resources.
	if (err != OK):
		return
		
	var code2 = plusCode.substr(0, 2)
	var code4 = plusCode.substr(2, 2)
	var rawdata := zipReader.read_file(code2 + "/" + code4 + "/" + plusCode + ".json")
	var realData = rawdata.get_string_from_utf8()
	var json = JSON.new()
	json.parse(realData)
	return json.data

func MakeMinOfflineTiles(plusCode):
	#var offlineNode = preload("res://PraxisMapper/Controls/OfflineData.tscn")
	#TODO: rename this later once it's done as cleanup
	var offlineNode = preload("res://PraxisMapper/Controls/MinOfflineData.tscn")
	var offlineInst = offlineNode.instantiate()
	add_child(offlineInst)
	await offlineInst.GetAndProcessData(plusCode,"suggestedmini")
	#offlineInst.tiles_saved
	remove_child(offlineInst)
	
static func GetStyle(style):
	var styleData = FileAccess.open("res://PraxisMapper/Styles/" + style + ".json", FileAccess.READ)
	if (styleData == null):
		return null
	else:
		var json = JSON.new()
		json.parse(styleData.get_as_text())
		return json.get_data()

static func DistanceDegreesToMetersLat(degrees):
	return degrees * metersPerDegree

static func DistanceDegreesToMetersLon(degrees, latDegrees):
	return degrees * metersPerDegree * cos(deg_to_rad(latDegrees))

static func DistanceMetersToDegreesLat(meters):
	return meters * oneMeterLat

static func DistanceMetersToDegreesLon(meters, latDegrees):
	return meters * oneMeterLat * cos(deg_to_rad(latDegrees))

static func MetersToFeet(meters):
	return meters * 3.281

static func GetCompassHeading():
	var gravity: Vector3 = Input.get_gravity()
	var pitch = atan2(gravity.z, -gravity.y) #rotation.x
	var roll = atan2(-gravity.x, -gravity.y)  #rotation.z
	var magnet = Input.get_magnetometer().rotated(-Vector3.FORWARD, roll).rotated(Vector3.RIGHT, pitch)
	
	var yaw_magnet = atan2(-magnet.x, magnet.z)
	return -yaw_magnet #Negative to match rotation values in Godot
