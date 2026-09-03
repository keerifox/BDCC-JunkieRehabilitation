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
		"Aaren", "Acorn", "Adair", "Aesther", "Aevari", "Aguilar", "Aiden", "Aki", "Akhona", "Akseli", "Albion", "Alexi", "Almer", "Almond", "Alvi", RNG.pick(["Amari", "Amir", "Amory"]), "Ander", "Aquila", "Archer", "Ardor", "Argyris", RNG.pick(["Aren", "Ari", "Aries", "Arin"]), "Arkian", "Arwyn", "Asher", "Aspen", RNG.pick(["Astra", "Astrid"]), "Auburn", "Audyn", "Augur", RNG.pick(["Aura", "Auren"]), "Averil", "Avion", "Axel", "Ayrie",
		#
		"Bailey", "Baltoro", "Bastien", "Bergen", "Bevy", "Birdie", "Biscuit", "Blaire", "Blankie", "Bliss", "Bodhi", "Brisken", "Brynn", "Bug", "Butch", "Buttercup",
		#
		RNG.pick(["Caelan", "Caelum"]), "Caine", "Cairo", "Calem", "Camryn", "Canvas", "Canyon", "Cappu", "Capri", "Carmilla", "Casimir", "Caspian", "Castano", "Castiel", "Catnip", "Ceno", RNG.pick(["Ceri", "Cerulean", "Cerys"]), "Cephei", "Ceylan", "Chains", "Charli", "Charon", "Charys", "Charreth", "Cherko", "Cheshyre", "Chiaki", "Chijou", "Chirayu", "Chisato", "Chisel", "Chitter", "Chloe", RNG.pick(["Choccy", "Chouquette"]), "Cider", RNG.pick(["Cieran", "Cieron", "Ciel"]), "Cimeres", "Cinder", RNG.pick(["Cinnamon", "Cinny"]), RNG.pick(["Citrine", "Citrus"]), "Clam", "Claw", "Cloud", "Clover", "Cocoa", "Coda", "Colt", "Cooper", "Corin", "Corvus", "Crayon", "Cris", "Cross",
		#
		"Daedric", "Daichi", "Daki", "Dash", "Davide", "Davin", "Daylin", "Delaine", "Delta", "Delwyn", "Demure", "Devi", "Dexie", "Dice", "Drifter", "Dune", "Duran", RNG.pick(["Dusker", "Dusky"]), "Dwyn",
		#
		"Echo", "Eden", "Eilian", RNG.pick(["Elie", "Ellie", "Elouiselle"]), "Elixir", "Elwyn", "Elys", "Ember", "Emlyn", "Emrys", "Encherie", "Enfys", "Enora", "Erlea", "Erryn", "Esen", "Essou", "Everly", "Ezri",
		#
		"Fable", "Fang", "Farren", "Feather", "Fenris", "Ferelith", "Fernley", "Fero", "Feryl", "Fidget", RNG.pick(["Finchie", "Finley", "Finn"]), "Fish", "Fives", "Flake", "Flann", "Fleur", "Flint", "Florian", "Flurry", "Fragile", "Freckles",
		#
		"Gabii", "Gage", "Gaia", "Gareth", "Garnet", "Gavyn", "Glade", "Glenne", RNG.pick(["Goro", "Gorou"]), "Gwyn",
		#
		"Halcyon", "Harlyn", "Haru", "Haskell", "Heathen", "Heijou", RNG.pick(["Hiccup", "Hickori", "Hikaru"]), "Hinata", "Hiro", "Howl", "Hudson",
		#
		"Ianthe", "Ichi", "Idelwyn", "Idris", "Imogen", "Imre", "Innes", "Inkie", "Isabeau", "Iseul", "Izumi",
		#
		"Jacey", "Jacket", "Jade", RNG.pick(["Jaelyn", "Jaetyn"]), "Jago", RNG.pick(["Jaiden", "Jayden"]), "Jaspen", "Javi", "Jaxie", "Jaycee", "Jelle", "Jett", "Jileath", "Junichi", "Juniper", "Juno", "Jyrki",
		#
		RNG.pick(["Kade", "Kaede", "Kaida"]), "Kaegan", "Kaenori", "Kagi", "Kahvi", RNG.pick(["Kai", "Kailath"]), RNG.pick(["Kaja", "Kajuu"]), RNG.pick(["Kale", "Kali"]), RNG.pick(["Kaori", "Kaoru"]), "Karkittu", "Karni", "Karsyn", "Kathan", "Kavukatt", RNG.pick(["Kavian", "Kavun"]), "Kaya", "Kayden", RNG.pick(["Kaze", "Kazeiu"]), RNG.pick(["Kei", "Keiki"]), RNG.pick(["Keita", "Kenta"]), "Kelby", "Kiawi", "Kiba", "Kieran", "Kigu", "Kijana", "Kimbra", RNG.pick(["Kimi", "Kimmie"]), "Kit", "Kiwen", "Kiyoshi", "Koen", "Kort", "Kosse", "Kouji", "Koutsouri", "Kreski", "Kritta", "Kuriko", "Kutto", RNG.pick(["Kyra", "Kyro"]), RNG.pick(["Kyubi", "Kyuu"]),
		#
		"Lace", "Lain", "Laith", RNG.pick(["Lani", "Lanjus"]), "Lapachi", "Lapis", "Lappy", "Lars", "Laufei", RNG.pick(["Lavender", "Lavi"]), "Layne", RNG.pick(["Lia", "Liv"]), RNG.pick(["Lexi", "Lexie", "Lexis"]), "Licky", RNG.pick(["Lin", "Linh"]), "Locke", "Lofie", "Loomy", "Lopi", RNG.pick(["Loreen", "Lorn"]), "Lorenz", "Lotte", RNG.pick(["Luca", "Luka"]), "Lucero", "Luna", "Lucky", RNG.pick(["Lumi", "Lumine"]), "Lycori",
		#
		RNG.pick(["Macchiato", "Maci"]), "Maia", RNG.pick(["Mako", "Makoto"]), "Malachi", "Mamoru", "Mana", "Mango", "Maple", "Marlow", "Marmutt", RNG.pick(["Mars", "Marv"]), "Mayhem", "Meph", "Meru", "Mesa", "Micha", "Midnite", "Mika", "Milky", "Mina", RNG.pick(["Mintea", "Minxie", "Mircea"]), "Miyu", "Mochi", "Moki", "Moon", "Moufette", "Moulton", "Muri",
		#
		"Nathalie", "Neon", "Nero", "Niko", "Nisha", "Nixx", "Nomad", RNG.pick(["Norica", "Norii"]), "Noxli", "Nuri",
		#
		"Oasis", "Oddball", "Onyx", "Oreo",
		#
		"Qiao", "Quiet", "Quinlan",
		#
		"Pancakes", RNG.pick(["Pasqual", "Pasqui"]), "Pastel", "Pastry", "Patch", "Pawnam", "Peaches", "Pidge", "Plush", RNG.pick(["Pockets", "Pocky"]), "Powder", "Puck",
		#
		"Rail", RNG.pick(["Raine", "Rainy"]), "Raewyn", "Rania", "Rascal", "Rasmus", RNG.pick(["Rei", "Reiko"]), "Remedy", "Remi", "Renko", "Renni", "Requiem", "Rhiens", "Rhys", "Ribbons", RNG.pick(["Rikkari", "Rikki"]), RNG.pick(["Rinneth", "Rinny"]), "River", "Riwi", "Rixen", "Roche", "Rook", "Rouge", "Rowan", "Roxali", "Rune", RNG.pick(["Ryuichi", "Ryuko"]),
		#
		"Sabine", "Sable", RNG.pick(["Saeko", "Saika", "Seiko", "Senko"]), "Salem", "Sammi", RNG.pick(["Satoru", "Satouji"]), "Savieon", "Scharfes", "Scruffy", "Seelie", "Seiryu", "Selby", "Seraph", "Serra", "Seti", "Sevin", RNG.pick(["Shae", "Shayhun"]), "Shion", "Shin", "Shiro", "Shiv", "Shonryu", "Sierra", "Siobhan", "Slug", "Slushie", "Smore", "Snuffie", "Soapy", "Sobel", RNG.pick(["Sock", "Socks"]), "Somni", "Song", RNG.pick(["Sorin", "Souren"]), "Soujun", "Soweli", "Sparkle", "Spike", "Splash", "Squishy", "Stiletto", "Stoibs", "Stoichi", "Styx", "Sunny", "Suwi", "Sven", "Syd", "Sylvie", "Syrup",
		#
		"Tales", RNG.pick(["Talon", "Talyn"]), "Tangerine", "Tangle", "Taro", "Tawreh", "Tayliah", "Thiago", "Thistle", RNG.pick(["Thorn", "Thorne"]), "Tidal", "Toffee", "Touki", "Treat", "Twine",
		#
		"Uno",
		#
		"Vale", "Vanilla", "Velvette", "Venti", "Verron", "Verse", "Vesper", "Vulkan",
		#
		"Willow", "Wulfric",
		#
		"Xanthe", "Xenia", "Xepher", "Xiang", "Xiao",
		#
		"Yachiru", "Yaei", "Yamato", "Yao", "Ying", RNG.pick(["Yukari", "Yuki", "Yuuki"]), "Yumekito",
		#
		"Zaiden", "Zaire", "Zenith", "Zephyr", "Zero", "Zippy", RNG.pick(["Zoe", "Zoey"]),
	]

func getCustomNames_machine() -> Array:
	return [
		"Ambi", "Arch", "Ascii",
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
		"Retro",
		#
		"Ternari", "Trace",
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
