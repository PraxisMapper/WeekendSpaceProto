extends RefCounted
class_name RecentTracker

#A dict of <string, float>. 
#string is plusCode, float is when the place counts as recent again.
var recentData = {}
var fileName = "user://Data/Recent.json"
var expireTime = 22 * 60 * 60 #22 hours, in seconds.

func Load():
	var recentFile = FileAccess.open(fileName, FileAccess.READ_WRITE)
	if (recentFile == null):
		return
	else:
		var json = JSON.new()
		json.parse(recentFile.get_as_text())
		var info = json.get_data()
		recentData = info
		recentFile.close()
	
func Save():
	var recentFile = FileAccess.open(fileName, FileAccess.WRITE)
	if (recentFile == null):
		print(FileAccess.get_open_error())
	
	var json = JSON.new()
	recentFile.store_string(json.stringify(recentData))
	recentFile.close()
	
func IsRecent(plusCode10):
	var currentTime = Time.get_unix_time_from_system()
	if recentData.has(plusCode10):
		if  currentTime > recentData[plusCode10]:
			recentData[plusCode10] = currentTime + expireTime
			return true
	else:	
		recentData[plusCode10] = currentTime + expireTime
		return true
	
	return false
