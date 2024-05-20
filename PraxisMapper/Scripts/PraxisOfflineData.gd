extends Node
class_name PraxisOfflineData

#Once we read a file from disk, keep it in memory. Odds are high the player will read it again.
static var allData = {}

static func GetDataFromZip(plusCode): #full, drawable offline data.
	if allData.has(plusCode):
		return allData[plusCode]
	#This needs to live nicely with the MinOffline version, and if the game is limited in
	#scope it could use the same source folder. The odds of the game using both built-in are 0.
	#though its possible it could include the minimum format as a fallback and download the full data.
	var code2 = plusCode.substr(0, 2)
	var code4 = plusCode.substr(2, 2)
	var zipReader = ZIPReader.new()
	
	#For This app, this will never have these built-in.
	#var err = await zipReader.open("res://OfflineData/" + code2 + "/" + code2 + code4 + ".zip")
	#if (err != OK):
	#TODO: should add a method that checks if the file exists AND OPENS,
	#because if its incomplete zipReader returns null.
	if FileAccess.file_exists("user://Data/Full/" + code2 + code4 + ".zip"):
		var err = await zipReader.open("user://Data/Full/" + code2 + code4 + ".zip")
		if err != OK:
			print("No FullOffline data found (or zip corrupt/incomplete) for " + plusCode)
			return 
		
	var rawdata := await zipReader.read_file(plusCode + ".json")
	var realData = await rawdata.get_string_from_utf8()
	var json = JSON.new()
	await json.parse(realData)
	var jsonData = json.data
	if jsonData == null: #no file in this zip, this area is missing or empty.
		return 
	
	var minVector = Vector2i(20000,20000)
	var maxVector = Vector2i(0,0)
	for category in jsonData.entries:
		for entry in jsonData.entries[category]:
			minVector = Vector2i(20000,20000)
			maxVector = Vector2i(0,0)
			#entry.p is a string of coords separated by a pipe in the text file.
			#EX: 0,0|20,0|20,20|20,0|0,0 is a basic square.
			var coords = entry.p.split("|", false)
			var polyCoords = PackedVector2Array()
			for i in coords.size():
				var point = coords[i].split(",")
				var workVector = Vector2i(int(point[0]), int(point[1]))
				polyCoords.append(workVector)
				
				if workVector.x > maxVector.x:
					maxVector.x = workVector.x
				if workVector.y > maxVector.y:
					maxVector.y = workVector.y
				if workVector.x < minVector.x:
					minVector.x = workVector.x
				if workVector.y < minVector.y:
					minVector.y = workVector.y
				
			entry.p = polyCoords
			entry.envelope = {min = minVector, max = maxVector}
	
	allData[plusCode] = jsonData
	return jsonData
	
static func GetPlacesPresent(plusCode):
	var data = await GetDataFromZip(plusCode.substr(0,6))
	var point = PlusCodeToDataCoords(plusCode)
	var results = []
	
	for category in data.entries:
		for entry in data.entries[category]:
			if entry.has("nid"):
				if IsPointInPlace(point, entry, 10):
					print("Found " + data.nameTable[str(entry.nid)] + " at " + plusCode)
					results.push_back({ 
						name  = data.nameTable[str(entry.nid)],
						category = category,
						typeId = entry.tid #would prefer name for display. Might need to load styles globally.
					})
	return results

static func IsPlusCodeInPlace(plusCode, place):
	var point = PlusCodeToDataCoords(plusCode)
	return IsPointInPlace(point, place, plusCode.size())
	
static func IsPointInPlace(point, place, size):
	#requires full drawing data. Minimized offline data is just a distance function vs the radius
	#point is a Vector2, placePoly is a PackedVector2Array from PraxisCore.GetDataFromZip
	
	#TODO: When loading data from JSON, calculate the min/max corners for each place
	#and save those to the place. Then, when scanning here, check if the point is inside
	#those min/max values. If its not, return false. If it is, do the full geometry scan.
	#LATER TODO: have the server do those calculations when creating the JSON files?
	#and then here check if they exist or not before calculating them here on demand.
	var inside = false
	
	#TODO: determine reasonable accuracy for this
	#this is a good estimate on paper but requires testing.
	var distanceCheck = 1 #cell10 distance
	if size == 11:
		distanceCheck = 4
	elif size == 12:
		distanceCheck = 13
	
	if place.gt == 1:
		inside = (point.distance_to(place.p[0]) < distanceCheck) #Treat as inside within a Cell10 or so.
	elif place.gt == 2:
		#Line. We do distance checking for speed/simplicity. 
		#For a line A-B and point C, if distance(A, C) + distance(B,C) == distance(A,C)
		#then it must be on that line. We can allow some variance to accommodate rounding on distances
		#in PlusCodes.
		var placePoly = place.p
		var prevCoordId = placePoly.size() - 1
		for i in placePoly.size():
			#CHeck if this line crosses our point's location
			var thisCoord = placePoly[i]
			var prevCoord = placePoly[prevCoordId]
			
			if thisCoord == prevCoord:
				if point == thisCoord:
					inside = true
				continue

			var pointDistances = point.distance_to(thisCoord) + point.distance_to(prevCoord)
			var lineDistance = thisCoord.distance_to(prevCoord)
			if abs((pointDistances - lineDistance)) < distanceCheck: 
				#print(str((point.distance_to(thisCoord)) + point.distance_to(prevCoord)) + " = " +  str(thisCoord.distance_to(prevCoord)))
				return true #we dont have to keep checking this set of lines.
				break
			
			prevCoordId = i
	elif place.gt == 3:
		var placePoly = place.p
		var prevCoordId = placePoly.size() - 1
		for i in placePoly.size():
			#CHeck if this line crosses our point's location in a fairly complex way.
			var thisCoord = placePoly[i]
			var prevCoord = placePoly[prevCoordId]
			var intersect = ((thisCoord.y > point.y) != (prevCoord.y > point.y)) and \
			(point.x < (prevCoord.x - thisCoord.x) * (point.y - thisCoord.y) / (prevCoord.y - thisCoord.y) + thisCoord.x) 
			
			if intersect:
				inside = !inside
		
			prevCoordId = i
	return inside

static func PlusCodeToDataCoords(plusCode):
	#This is the Cell10 coords, because we multiply the value by the cell12 pixels on the axis.
	#TODO: check plusCode size and/or highPrecisionMode, adjust results.
	plusCode = plusCode.replace("+", "")
	var testPointY = (PlusCodes.GetLetterIndex(plusCode[6]) * 500) + (PlusCodes.GetLetterIndex(plusCode[8]) * 25)
	var testPointX = (PlusCodes.GetLetterIndex(plusCode[7]) * 320) + (PlusCodes.GetLetterIndex(plusCode[9]) * 16)
	var point = Vector2(testPointX, testPointY)
	return point
