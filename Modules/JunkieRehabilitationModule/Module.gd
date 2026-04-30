extends Module
class_name JunkieRehabilitationModule

func getFlags():
	return {
		"Scenario_MissingPerson_ChanceMillionth": flag(FlagType.Number),
		"Scenario_MissingPerson_Name": flag(FlagType.Text),
		"Scenario_MissingPerson_PronounThem": flag(FlagType.Text),
		"Scenario_MissingPerson_SeekerName": flag(FlagType.Text),
		"Scenario_MissingPerson_SearchAttempts": flag(FlagType.Number),
	}

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
	GlobalRegistry.registerScene("res://Modules/JunkieRehabilitationModule/Scenes/Overwrites/DrugDenEventWhoreScene.gd")
	GlobalRegistry.registerScene("res://Modules/JunkieRehabilitationModule/Scenes/Overwrites/DrugDenEventWhoreSubScene.gd")

func getPronounChancePercent_they() -> float:
	return 9.0 # %, set to any desired amount

func getPronounChancePercent_it() -> float:
	return 1.0 # %, set to any desired amount

func getPronounChancePercent_default() -> float:
	return max(
		(
				100.0
			- getPronounChancePercent_they()
			- getPronounChancePercent_it()
		),
		0.0
	)

func pickPronounsGender():
	return RNG.pickWeightedPairs([
		[
			null,
			getPronounChancePercent_default()
		],
		[
			Gender.Androgynous,
			getPronounChancePercent_they()
		],
		[
			Gender.Other,
			getPronounChancePercent_it()
		],
	])
