extends LootList

func _init():
	handlesAll = true

func getLoot(_id, _characterID, _battleName):
	if((GM.main == null) || !is_instance_valid(GM.main) || GlobalRegistry.getModule("ElizaModule") == null || !GlobalRegistry.getModule("ElizaModule").canStartDrugDenRun()):
		return []

	if(_id == "junkie"):
		return []

	var chanceMod:float = 1.0

	if(_id == "junkiestash"):
		chanceMod = 0.1
	elif(_id == "medical"):
		chanceMod = 1.0
	else:
		chanceMod = 0.5

	return [
		[5.0*chanceMod, [["JunkieRehabilitationPill", 1, 1]]],
	]
