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
	events = [
		"res://Modules/JunkieRehabilitationModule/Events/JunkieRehabilitationConsumablesQuickAccessEvent.gd"
	]
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

	GlobalRegistry.registerScene("res://Modules/JunkieRehabilitationModule/Scenes/JunkieRehabilitationConsumablesQuickAccessScene.gd")

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

func getCustomNameChance_max() -> float:
	return 60.0 # %, set to any desired amount

func getCustomNames() -> Array:
	return [
		"Aaren", "Acorn", "Adair", "Aesther", "Aiden", "Aki", "Akhona", "Albion", "Alexi", "Almer", "Almond", "Alvi", "Amari", "Amory", "Ander", "Aquila", "Archer", "Ardor", RNG.pick(["Aren", "Ari", "Aries", "Arin"]), "Arkian", "Arwyn", "Asher", "Aspen", "Astra", "Auburn", "Audyn", "Augur", RNG.pick(["Aura", "Auren"]), "Avion", "Axel",
		#
		"Bailey", "Baltoro", "Bergen", "Bevy", "Birdie", "Biscuit", "Blaire", "Blankie", "Bliss", "Brisken", "Brynn", "Bug", "Butch", "Buttercup",
		#
		"Caelan", "Caine", "Cairo", "Camryn", "Canvas", "Cappu", "Capri", "Carmilla", "Casimir", "Caspian", "Castiel", "Catnip", "Ceno", RNG.pick(["Ceri", "Cerulean", "Cerys"]), "Cephei", "Ceylan", "Charli", "Charon", "Charys", "Charreth", "Cherko", "Chiaki", "Chijou", "Chirayu", "Chisato", "Chloe", "Chouquette", "Cieron", "Cinder", RNG.pick(["Cinnamon", "Cinny"]), RNG.pick(["Citrine", "Citrus"]), "Clam", "Claw", "Cloud", "Cocoa", "Coda", "Corin", "Corvus", "Crayon", "Cris", "Cross",
		#
		"Daki", "Davide", "Davin", "Daylin", "Delaine", "Delwyn", "Demure", "Devi", "Dice", "Dune", "Dusky", "Dwyn",
		#
		"Echo", "Eden", "Eilian", RNG.pick(["Elie", "Ellie", "Elouiselle"]), "Elwyn", "Ember", "Emlyn", "Emrys", "Encherie", "Enfys", "Erlea", "Erryn", "Esen", "Essou", "Everly", "Ezri",
		#
		"Fable", "Fang", "Farren", "Feather", "Fenris", "Ferelith", "Fernley", "Fero", "Feryl", "Fidget", RNG.pick(["Finley", "Finn"]), "Flann", "Fleur", "Flint", "Florian", "Flurry", "Fragile", "Freckles",
		#
		"Gabii", "Gage", "Garnet", "Gavyn", "Glade", "Glenne", RNG.pick(["Goro", "Gorou"]), "Gwyn",
		#
		"Halcyon", "Harlyn", "Haru", "Haskell", "Hikaru", "Hinata", "Hiro", "Howl", "Hudson",
		#
		"Ianthe", "Ichi", "Idelwyn", "Idris", "Innes", "Iseul", "Izumi",
		#
		"Jacey", "Jacket", "Jade", RNG.pick(["Jaelyn", "Jaetyn"]), "Jago", RNG.pick(["Jaiden", "Jayden"]), "Jaspen", "Jaxie", "Jaycee", "Jelle", "Jileath", "Juniper", "Juno", "Jyrki",
		#
		RNG.pick(["Kaede", "Kaida"]), "Kaegan", RNG.pick(["Kai", "Kailath"]), "Kaja", "Kale", RNG.pick(["Kaori", "Kaoru"]), "Karkittu", "Karni", "Karsyn", "Kathan", "Kavukatt", "Kavun", "Kayden", "Kazeiu", "Kei", "Kelby", "Kiba", "Kieran", "Kigu", "Kijana", "Kimbra", "Kimmie", "Kit", "Kort", "Kosse", "Koutsouri", "Kreski", "Kuriko", "Kutto", RNG.pick(["Kyra", "Kyro"]), RNG.pick(["Kyubi", "Kyuu"]),
		#
		"Lain", "Laith", "Lanjus", "Lapachi", "Lapis", "Laufei", RNG.pick(["Lavender", "Lavi"]), "Layne", RNG.pick(["Lexi", "Lexie", "Lexis"]), "Lin", "Lofie", RNG.pick(["Loreen", "Lorn"]), "Lorenz", RNG.pick(["Luca", "Luka"]), "Lucero", "Luna", "Lucky", RNG.pick(["Lumi", "Lumine"]), "Lycori",
		#
		RNG.pick(["Macchiato", "Maci"]), "Maia", RNG.pick(["Mako", "Makoto"]), "Mana", "Mango", "Marlow", "Marmutt", "Mars", "Mayhem", "Meph", "Mesa", "Micha", "Midnite", "Mika", "Milky", "Mina", "Mintea", "Miyu", "Mochi", "Moki", "Moufette", "Muri",
		#
		"Neon", "Niko", "Nisha", "Nomad", "Norica", "Noxli", "Nuri",
		#
		"Oasis", "Oddball", "Onyx", "Oreo",
		#
		"Qiao", "Quiet", "Quinlan",
		#
		"Pancakes", "Pasqui", "Pastel", "Patch", "Pawnam", "Peaches", "Pidge", "Plush", "Puck",
		#
		"Rail", "Raine", "Raewyn", "Rania", "Rascal", RNG.pick(["Rei", "Reiko"]), "Remedy", "Remi", "Renni", "Requiem", "Ribbons", "Rikki", "Rinny", "River", "Roche", "Rook", "Rouge", "Rowan", "Rune", "Ryuko",
		#
		"Sabine", "Sable", RNG.pick(["Saeko", "Saika", "Seiko", "Senko"]), "Salem", "Sammi", "Satouji", "Savieon", "Scharfes", "Scruffy", "Seelie", "Selby", "Seraph", "Serra", "Seti", "Sevin", RNG.pick(["Shae", "Shayhun"]), "Shin", "Shiro", "Shiv", "Shonryu", "Sierra", "Siobhan", "Slug", "Smore", RNG.pick(["Sock", "Socks"]), "Somni", "Song", RNG.pick(["Sorin", "Souren"]), "Soujun", "Soweli", "Sparkle", "Spike", "Splash", "Squishy", "Stiletto", "Stoibs", "Stoichi", "Styx", "Sunny", "Suwi", "Sven", "Syrup",
		#
		RNG.pick(["Talon", "Talyn"]), "Tangerine", "Tangle", "Thistle", "Thorn", "Toffee", "Touki", "Treat",
		#
		"Vale", "Vanilla", "Velvette", "Venti", "Verron", "Verse", "Vesper", "Vulkan",
		#
		"Willow", "Wulfric",
		#
		"Xanthe", "Xenia", "Xepher", "Xiang", "Xiao",
		#
		"Yachiru", "Yaei", "Yamato", "Yao", "Ying", RNG.pick(["Yuki", "Yuuki"]),
		#
		"Zaiden", "Zaire", "Zenith", "Zero", RNG.pick(["Zoe", "Zoey"]),
	]

func getCustomNames_machine() -> Array:
	return [
		"Ambi", "Arch",
		#
		"Byte",
		#
		"Curl",
		#
		"Echo", "Epoch",
		#
		"Glitch",
		#
		"Keygen",
		#
		"Lua",
		#
		"Mosfet",
		#
		"Node",
		#
		"Patch", "Proton",
		#
		"Trace",
		#
		"Servo", "Shader", "Sudo", "Sync",
		#
		"Vertex", "Void", "Vulkan",
		#
		"Yubi",
		#
		RNG.pick(["Dexel", "Pixel", "Voxel"]),
	]

func pickCustomName(pronounsGenderOrNull) -> String:
	var customNames:Array = getCustomNames()
	#testCustomNameUniqueness()

	if( (pronounsGenderOrNull != null) && ( pronounsGenderOrNull in [Gender.Androgynous, Gender.Other] ) ):
		if( RNG.chance(10.0) ):
			return ""
	else:
		if( !RNG.chance( min( ( customNames.size() * 0.05 ), getCustomNameChance_max() ) ) ):
			return ""

	var randomName:String = RNG.pick(customNames)

	if( randomName == GM.pc.getName() ):
		return ""

	return randomName

func pickCustomName_machine() -> String:
	var customNames:Array = getCustomNames_machine()

	var randomName:String = RNG.pick(customNames)

	if( randomName == GM.pc.getName() ):
		return "Null"

	return randomName

func testCustomNameUniqueness():
	var ignoreByKey:Dictionary = {}
	for n in 20:
		var customNames:Array = getCustomNames()
		for customName in customNames:
			if( ignoreByKey.has(customName) ):
				continue
			if(customName in RNGData.femaleNames):
				ignoreByKey[customName] = true
				print("[JunkieRehabilitation] Notice: \""+ customName +"\" already present in RNGData.femaleNames.")
			elif(customName in RNGData.maleNames):
				ignoreByKey[customName] = true
				print("[JunkieRehabilitation] Notice: \""+ customName +"\" already present in RNGData.maleNames.")
