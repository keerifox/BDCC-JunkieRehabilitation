extends Module
class_name JunkieRehabilitationModule

func getFlags():
	return {}

func _init():
	id = "JunkieRehabilitationModule"
	author = "keerifox"
	
	scenes = []
	characters = []
	items = [
		"res://Modules/JunkieRehabilitationModule/Inventory/Items/JunkieRehabilitationPill.gd",
	]
	events = []
	quests = []
	worldEdits = []
	computers = []

	GlobalRegistry.registerLootListFolder("res://Modules/JunkieRehabilitationModule/Inventory/LootLists/")

func postInit():
	GlobalRegistry.registerScene("res://Modules/JunkieRehabilitationModule/Scenes/Overwrites/DrugDenEncounterBossScene.gd")
	GlobalRegistry.registerScene("res://Modules/JunkieRehabilitationModule/Scenes/Overwrites/DrugDenEncounterFirstScene.gd")
	GlobalRegistry.registerScene("res://Modules/JunkieRehabilitationModule/Scenes/Overwrites/DrugDenEncounterInstantFightScene.gd")
