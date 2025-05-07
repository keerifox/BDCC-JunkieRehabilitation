extends ItemBase

func _init():
	id = "JunkieRehabilitationPill"

func getVisibleName():
	return "JunkieBeMine"

func getDescription():
	return "A pill that may assist in reducing dependency on psychoactive substances."

func getPrice():
	return 100

func getSellPrice():
	return 10

func canSell():
	return true

func canCombine():
	return true

func getInventoryImage():
	return "res://Modules/JunkieRehabilitationModule/Images/Items/medical/junkie_rehabilitation_pill.png"

func getTags():
	if((GM.main != null) && is_instance_valid(GM.main) && GlobalRegistry.getModule("ElizaModule") != null && GlobalRegistry.getModule("ElizaModule").canStartDrugDenRun()):
		return [
			ItemTag.SoldByMedicalVendomat,
			ItemTag.KeptAfterDrugDenRun,
		]
	else:
		return []

func getBuyAmount():
	return 1

func getItemCategory():
	return ItemCategory.Medical
