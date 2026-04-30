extends SceneBase

const RehabilitatedJunkieGenerator = preload("res://Modules/JunkieRehabilitationModule/Characters/Dynamic/Generator/RehabilitatedJunkieGenerator.gd")

var npcID:String = ""
var wonState:String = ""
var expWin:int = 50

var scenario_missingPerson_started:bool = false
var scenario_missingPerson_foundForSeekerName:String = ""

func _init():
	sceneID = "DrugDenEncounterTemplateScene"

func generateJunkieNPCID(_isBoss:bool = false) -> String:
	var theGenerator := DrugDenJunkieGenerator.new()
	var theChar:BaseCharacter = theGenerator.generate({
		NpcGen.Temporary: true,
		NpcGen.IsBoss: _isBoss,
	})
	theChar.npcPronounsGender = GlobalRegistry.getModule("JunkieRehabilitationModule").pickPronounsGender()

	var theID:String = theChar.id
	
	return theID

func rehabilitateJunkie() -> DynamicCharacter:
	var junkieChar = getCharacter(npcID)
	junkieChar.setTemporary(false)

	var generator = RehabilitatedJunkieGenerator.new()
	var inmateChar:DynamicCharacter = generator.process(junkieChar)
	GM.main.addDynamicCharacterToPool(inmateChar.id, CharacterPool.Inmates)
	return inmateChar

func resolveCustomCharacterName(_charID):
	if(_charID == "npc"):
		return npcID

func startFightWithNPC(theBattleName:String = "DrugDenEncounter"):
	runScene("FightScene", [npcID, theBattleName], "encounterFight")

func returnJunkieRehabilitationPillsFromDrugDenStashToPC():
	var drugDenChar:BaseCharacter = GlobalRegistry.getCharacter("DrugDenStash")

	var itemsToReturnToPC:Array = []
	for itemInDrugDenStash in drugDenChar.getInventory().getItems():
		if(itemInDrugDenStash.id == "JunkieRehabilitationPill"):
			itemsToReturnToPC.append(itemInDrugDenStash)

	for itemToReturn in itemsToReturnToPC:
		drugDenChar.getInventory().removeItem(itemToReturn)
		GM.pc.getInventory().addItem(itemToReturn)

func scenario_missingPerson_rollForShouldStart() -> bool:
	var wasScenarioTriggered:bool = false

	var wasScenarioJustCompleted:bool = (scenario_missingPerson_foundForSeekerName != "")

	if(wasScenarioJustCompleted == true):
		wasScenarioTriggered = false
		return wasScenarioTriggered

	var isScenarioAlreadyActive:bool = scenario_missingPerson_isActive()

	if(isScenarioAlreadyActive == true):
		wasScenarioTriggered = false
		return wasScenarioTriggered

	var SCENARIO_CHANCE_MILLIONTH_INITIAL_VALUE:int = -10000
	var SCENARIO_CHANCE_MILLIONTH_INCREMENT:int = 2000

	var chanceAdditiveMillionth:int = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_ChanceMillionth", SCENARIO_CHANCE_MILLIONTH_INITIAL_VALUE)
	chanceAdditiveMillionth += SCENARIO_CHANCE_MILLIONTH_INCREMENT
	GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_ChanceMillionth", chanceAdditiveMillionth)

	wasScenarioTriggered = RNG.chance(chanceAdditiveMillionth / 10000.0)

	if(wasScenarioTriggered == true):
		GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_ChanceMillionth", SCENARIO_CHANCE_MILLIONTH_INITIAL_VALUE)

	return wasScenarioTriggered

func scenario_missingPerson_isActive() -> bool:
	return ( GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_Name", "") != "" )

func scenario_missingPerson_generateDetails() -> Array:
	var missingPerson_details:Array = []

	var missingPerson_them:String = "them"
	var randomPronounsGender = GlobalRegistry.getModule("JunkieRehabilitationModule").pickPronounsGender()

	if(randomPronounsGender == Gender.Androgynous):
		missingPerson_them = "them"
	elif(randomPronounsGender == Gender.Other):
		missingPerson_them = "it"
	else:
		missingPerson_them = (
				"him"
			if ( GM.main.getEncounterSettings().generateGender() in [NpcGender.Male, NpcGender.Peachboy] )
			else "her"
		)

	var defeatedJunkie_name:String = getCharacter(npcID).getName()
	var missingPerson_name:String = defeatedJunkie_name

	while(missingPerson_name == defeatedJunkie_name):
		if(missingPerson_them == "her"):
			missingPerson_name = RNG.randomFemaleName()
		elif(missingPerson_them == "him"):
			missingPerson_name = RNG.randomMaleName()
		else:
			missingPerson_name = RNG.randomFemaleName() if RNG.chance(50) else RNG.randomMaleName()

	missingPerson_details = [
		missingPerson_name,
		missingPerson_them,
		defeatedJunkie_name
	]

	GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_Name", missingPerson_name)
	GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_PronounThem", missingPerson_them)
	GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SeekerName", defeatedJunkie_name)
	GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SearchAttempts", 0)

	return missingPerson_details

func scenario_missingPerson_checkForWasCompleted() -> bool:
	var wasScenarioCompleted:bool = false

	var missingPerson_searchAttempts:int = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SearchAttempts", 0)
	missingPerson_searchAttempts += 1
	GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SearchAttempts", missingPerson_searchAttempts)

	var defeatedJunkie_character:BaseCharacter = getCharacter(npcID)

	var missingPerson_them:String = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_PronounThem", "")
	var defeatedJunkie_them:String = defeatedJunkie_character.himHer()

	if(defeatedJunkie_them != missingPerson_them):
		wasScenarioCompleted = false
		return wasScenarioCompleted

	var completionChance:float = -20.0 + 15.0 * missingPerson_searchAttempts
	wasScenarioCompleted = RNG.chance(completionChance)

	if(wasScenarioCompleted == true):
		var missingPerson_name:String = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_Name", "")

		if(missingPerson_name != ""):
			defeatedJunkie_character.npcName = missingPerson_name

		var missingPerson_seekerName:String = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SeekerName", "")

		if(missingPerson_seekerName != ""):
			scenario_missingPerson_foundForSeekerName = missingPerson_seekerName

		GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_Name", "")
		GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_PronounThem", "")
		GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SeekerName", "")
		GM.main.setFlag("JunkieRehabilitationModule.Scenario_MissingPerson_SearchAttempts", 0)

	return wasScenarioCompleted

func _react_scene_end(_tag, _result):
	if(_tag == "encounterFight"):
		processTime(10 * 60)
		var battlestate = _result[0]
		
		if(GM.main.DrugDenRun != null):
			GM.main.DrugDenRun.markEncounterAsCompleted(GM.pc.getLocation())
		
		if(battlestate == "win"):
			#setState("won_encounter")
			if(wonState == ""):
				returnJunkieRehabilitationPillsFromDrugDenStashToPC()
				setState("wonFight")
			else:
				setState(wonState)
			addExperienceToPlayer(expWin)
			
			if(GM.main.DrugDenRun.shouldShowLevelUpScreen()):
				runScene("DungeonLevelUpScene")
		else:
			setState("lost_encounter")

	if(_tag == "defeated_sex"):
		var sexResult:SexEngineResult = _result[0]
		var gotUncon:bool = sexResult.isSubUnconscious("pc")
		
		if(gotUncon):
			setState("encounter_fully_rekt")
		else:
			setState("encounter_survived_sex")
		return

func encounter_run():
	if(state == "wonFight"):
		playAnimation(StageScene.Duo, "stand", {npc=npcID, npcAction="defeat"})

		saynn("The junkie "+("boss " if(sceneID == "DrugDenEncounterBossScene") else "")+"has been defeated!")

		var pillsCount:int = GM.pc.getInventory().getAmountOf("JunkieRehabilitationPill")
		var desc:String = "Force them to swallow a \"JunkieBeMine\" pill, which will make them leave this place and return to the cellblock.\n[i]You have "+str(pillsCount)+" pill"+("" if(pillsCount == 1) else "s")+" left.[/i]"
		if(pillsCount < 1):
			addDisabledButton("Rehabilitate", desc)
		else:
			addButton("Rehabilitate", desc, "gave_pill")

		addButton("Leave", "Just leave. You'll likely never meet them again, but that's okay.", "left_without_giving_pill")

	if(state == "gave_pill"):
		playAnimation(StageScene.SexOral, "start", {pc="pc", npc=npcID})

		saynn("You produce a \"JunkieBeMine\" pill and force {npc.him} to swallow "+ ( "the pill" if( getCharacter(npcID).himHer() == "it" ) else "it" ) +".")

		var possible:Array = [
			"No.. What have you-",
			"F- Fucker.. What are you-",
			"I am not done with you yet.. Fuck..",
			"Get your hand- Fshkf..",
			"How about you shove this up your-",
			"I will mess you up- mffmfh..",
			"I will bite your fucking arm off- ffhfmm..",
		]

		if(sceneID == "DrugDenEncounterBossScene"):
			possible.append_array([
				"Whore. You don't deserve even a fraction of this lab.. What are y-",
				"You think you got this all figured out? My thugs will- The fuck are yo..",
				"You're still an amateur that would waste this state-of-the-art equipment to make a fucking painkil- Get your dirty hands off me! Mfhhsfh-"
			])
		else:
			possible.append_array([
				"So nice of you to share~",
				"Oooh new product! Gimme-ahff~",
				"Mm, you like watching me swallow? Freak~.. mmhf-",
				"No need to be so.. hhf.. forcefhul.. Let me savor it..",
				"W- Would you have some milk to help me swallow? P- Please... mffhfm..",
				"Fuck off-.. W- Wait.. Let me try it..",
			])
		
		saynn("[say=npc]"+RNG.pick(possible)+"[/say]")

		addButton("Continue", "See what happens next", "swallowed_pill")

	if(state == "swallowed_pill"):
		playAnimation(StageScene.Sleeping, "sleep", {pc=npcID})

		if(scenario_missingPerson_started == true):
			saynn( RNG.pick([
				"With no stamina left to fight you, {npc.name} falls onto {npc.his} side. {npc.His} body lays motionless until {npc.his} arm suddenly snaps at you, tightly grabbing you by the ankle, as {npc.his} lips quietly utter something.",
				"Noticeably weakened after the fight, {npc.name} lays motionless, staring at- No, *through* you. {npc.His} expression is completely void. Moments after, a quiet murmur echoes past, while {npc.his} lips show no sign of motion."
			]) )

			var missingPerson_name = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_Name", "MissingInmate")
			var missingPerson_them = GM.main.getFlag("JunkieRehabilitationModule.Scenario_MissingPerson_PronounThem", "them")

			saynn("[say=npc]"+RNG.pick([
				( missingPerson_name + "... Find.. " + missingPerson_name + ".." ),
				( missingPerson_name + "... Save.. " + missingPerson_them + ".." ),
			])+"[/say]")

			if( RNG.chance(50) ):
				saynn("Huh, someone they know? You nod, a little stunned, as medicine eventually kicks in, making their paw feel numb.")
				saynn("A name is not a lot of information to go by, especially in a place where noone cares to introduce themselves. You're hit with a blunt reminder that people make connections even under living conditions such as these.")
			else:
				saynn("Don't tell me the sole reason they're in the den is to get someone out.. Fuck.. That was their only chance to blend in with the rest of the junkies.")
				saynn("You just wanted to be someone's savior, didn't you. Better hope the person they were looking for has enough breaths to draw. All you have is a damn name.")
		else:
			saynn( RNG.pick([
				"Weakened after the fight, {npc.name} falls onto {npc.his} spine, slipping into slumber.",
				"There is no stamina left in {npc.name} to resist, and {npc.he} {npc.youVerb('collapse')} on {npc.his} side, beside you.",
				"No more words leave {npc.nameS} mouth. For a brief moment, {npc.he} {npc.youVerb('stare')} at you with an alert expression, then.. {npc.youVerb('doze')} off.",
				"Lacking strength to defy you, {npc.name} flops on {npc.his} back, closely following your movements for a few seconds, before inevitably falling asleep.",
			]) )

			var pcPersonality:Personality = GM.pc.getPersonality()
			var pcFetishHolder:FetishHolder = GM.pc.getFetishHolder()

			var pcPersonalitySubbyScore:float = pcPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
			var pcIsSubby:bool = pcPersonalitySubbyScore > 0.4
			var pcIsDommy:bool = pcPersonalitySubbyScore < -0.4

			var pcInterestInRiggingOthers:float = pcFetishHolder.scoreFetishMax({ Fetish.Rigging: 1.0 })
			var pcLikesRiggingOthers:bool = pcInterestInRiggingOthers >= 0.5

			var junkieSpecies:Array = getCharacter(npcID).getSpecies()

			var possible:Array = [
				"Let's hope this works..",
				"That should take care of your addiction..",
				"Hmph. Maybe you are worth surrendering to..",
				"I'm a little selfish, huh..",
				"Sorry, can't afford to lose you to this place.",
				"I hope we meet again.",
				"Such a hot thing.",
				"What a charming thing.",
				"I'd like to know you a little more.. intimately..",
				"Once I'm done wandering this miserable place, I'll make sure you're taken good care of.",
				"We've only just met, and I already feel addicted.. Perhaps I'm not the best person to judge you..",
				"I really don't want to forget you..",
				"A few more creatures like you, and the cellblock might just feel like a dream..",
				"It's tempting to just.. lie beside you, for hours.. But I have to make sure the nearby floors are as safe as they can be.",
				"What was I doing before this? Right.. Honestly, with distractions shaped like you, I could never complain..",
				"Your voice is so damn hot... Have you passed out already? No worries, I have a feeling I'll be saying that much more often now..",
				"You've really caught my attention, you know..",
				"If.. I'm not your type, I'll find someone just for you.",
				"I'll have to make it up to you later..",
				"A fleeting memory of you is simply not enough..",
				"This damned place may cloud my judgement, but I've no second thoughts about getting you out of here.",
				"You're a bad influence on me~",
				"You must've been through a lot. The cellblock's no Elysium, but I've got plans on changing that.",
				"The prison staff doesn't give two shits for anyone rotting here. They find it useful. You'll have plenty of utensils, you know.. When the consequences are served.",
				"I know I'd go through a hundred floors just to find you again. This way I know you'll make it through.",
				"The cellblock's not inherently safer, but it's one place I have contacts in. They'll ensure nobody gives you any problems that you won't ask for.",
				"Hey it was you who pounced at me, I don't let go so easily~",
				"There's so many things I want to tell you..",
				"Is this ethical? I truthfully don't know. Something something the lesser weevil.",
				"I cannot save everyone. I'm well aware. Each chance I'm given is paid forward. Use yours well, dear.",
				"This doesn't make us anything. I hope we get close eventually..",
				"Would you even remember me?",
			]

			if(pcIsDommy == true):
				possible.append_array([
					"You'd make an excellent plaything, dear. Don't let anyone snatch you before I get a good look holding you by the collar~",
					"Next time I see you roam the cellblock in full consciousness, I'm pinning you against the nearest wall and making you my own~",
				])
			elif(pcIsSubby == true):
				possible.append_array([
					"I'm already envisioning all the things I'd let you do to me..",
					"Guh.. Can't wait for you to play with me..",
					"Why does everyone here have to be so hot.. Fuck..",
				])

			if(pcLikesRiggingOthers == true):
				possible.append_array([
					"I'm already so tempted to bind you in ropes, hh.. If it didn't complicate your traversal at a time when I need you to safely leave the den, I definitely would~",
				])

			for junkieSpeciesId in junkieSpecies:
				if( junkieSpeciesId.ends_with("eon") || junkieSpeciesId.ends_with("vee") ):
					possible.append_array([
						"I don't care what the data on your collar says, you're a shiny to me~",
					])

					break

			saynn("[say=pc]"+RNG.pick(possible)+"[/say]")

		addMessage("{npc.name} can now be found around the cellblock.")

		if(scenario_missingPerson_foundForSeekerName != ""):
			addMessage(
					"\n[color=#DDFFCC]"
				+ RNG.pick([
					( "You found someone "+ scenario_missingPerson_foundForSeekerName +" asked you to save." ),
					( "This is, undoubtedly, the person that "+ scenario_missingPerson_foundForSeekerName +" wanted you to find." ),
				])
				+ " "
				+ RNG.pick([
					( "You just don't know that yet." ),
					( "You'd immediately feel more at ease, but it's not until you see the two of them in the cellblock that you get to sigh in relief." ),
				])
				+ "[/color]"
			)

		addButton("Leave", "Let them recover at their own pace.", "after_swallowed_pill")
		
	if(state == "lost_encounter"):
		playAnimation(StageScene.Duo, "defeat", {npc=npcID})
		
		saynn("You lost! Looks like the junkie is eager to fuck you.")
		
		addButton("Continue", "See what happens next", "start_defeated_sex")
	
	if(state == "encounter_survived_sex"):
		removeCharacter(npcID)
		saynn("You managed to endure the onslaught! Time to run!")
		
		addButton("Continue", "See what happens next", "endthescene")
		
	if(state == "encounter_fully_rekt"):
		removeCharacter(npcID)
		playAnimation(StageScene.Sleeping, "sleep")
		
		saynn("You got chocked out completely..")
		
		saynn("All you see is darkness..")
		
		addButton("Continue", "See what happens next", "encounter_endrun")
	
	if(state == "encounter_medical"):
		clearCharacter()
		playAnimation(StageScene.Sleeping, "sleep")
		addCharacter("eliza")
		aimCameraAndSetLocName("medical_hospitalwards")
	
		saynn("[say=eliza]Wakey-wakey![/say]")
		
		saynn("You open your eyes.. and realize that you're somewhere in the medical wing.")
		
		saynn("[say=eliza]Nanobots worked like a charm! I treated some of your injuries while you were taking a nap. Eat this muffin too, you're starving![/say]")
	
		saynn("She gives you a muffin. You eat it immediately. It tastes like the best thing you have ever eaten in your life.")
	
		saynn("[say=pc]Thanks..[/say]")
		
		saynn("She points at a drawer near your hospital bed.")
		
		saynn("[say=eliza]All your things are in there.[/say]")
		
		saynn("You get up, grab all your belongings and prepare to follow Eliza.")
		
		addButton("Follow", "See where she will bring you", "encounter_back_to_lobby")
		
	if(state == "encounter_back_to_lobby"):
		GM.pc.setLocation("med_lobbymain")
		aimCameraAndSetLocName("med_lobbymain")
		playAnimation(StageScene.Duo, "stand", {npc="eliza"})
		
		saynn("Eliza brings you out into the lobby.")
		
		saynn("[say=eliza]Take care now![/say]")
		
		addButton("Continue", "Time to go!", "endthescene")
		addButton("Run back", "Rush back to the hidden drug den entrance", "encounter_endthescene_rushback")
	
func encounter_react(_action: String, _args):
	if(_action == "gave_pill"):
		GM.pc.getInventory().removeXOfOrDestroy("JunkieRehabilitationPill", 1)
		var _inmateChar:DynamicCharacter = rehabilitateJunkie()

		if( scenario_missingPerson_isActive() == true ):
			scenario_missingPerson_checkForWasCompleted()

		setState("gave_pill")
		return true
	if(_action == "swallowed_pill"):
		if( scenario_missingPerson_rollForShouldStart() == true ):
			scenario_missingPerson_generateDetails()
			scenario_missingPerson_started = true

		setState("swallowed_pill")
		return true
	if(_action == "after_swallowed_pill"):
		playAnimation(StageScene.Solo, "stand")

		if(sceneID == "DrugDenEncounterBossScene"):
			setState("wonBossFight")
		else:
			endScene()

		return true
	if(_action == "left_without_giving_pill"):
		playAnimation(StageScene.Solo, "stand")

		if(sceneID == "DrugDenEncounterBossScene"):
			setState("wonBossFight")
		else:
			endScene()

		return true
	if(_action == "start_defeated_sex"):
		getCharacter(npcID).prepareForSexAsDom()
		runScene("GenericSexScene", [npcID, "pc", SexType.DefaultSex, {SexMod.SubMustGoUnconscious:true, SexMod.DisableDynamicJoiners:true}], "defeated_sex")
		return true
	if(_action == "encounter_endrun"):
		GM.main.processTime(2*60*60)
		GM.pc.setLocation("medical_hospitalwards")
		GM.main.stopDungeonRun()
		GM.pc.addPain(-GM.pc.getPain())
		GM.pc.addLust(-GM.pc.getLust())
		GM.pc.addStamina(GM.pc.getMaxStamina())
		setState("encounter_medical")
		return true
	if(_action == "encounter_back_to_lobby"):
		setState("encounter_back_to_lobby")
		return true
	if(_action == "encounter_endthescene_rushback"):
		GM.pc.setLocation("yard_deadend2")
		endScene()
		return true
	
	return false

func saveData():
	var data = .saveData()
	
	data["npcID"] = npcID
	data["scn_mp_started"] = scenario_missingPerson_started
	data["scn_mp_foundForSeekerName"] = scenario_missingPerson_foundForSeekerName
	
	return data
	
func loadData(data):
	.loadData(data)
	
	npcID = SAVE.loadVar(data, "npcID", "")
	scenario_missingPerson_started = SAVE.loadVar(data, "scn_mp_started", false)
	scenario_missingPerson_foundForSeekerName = SAVE.loadVar(data, "scn_mp_foundForSeekerName", "")

func getSceneCreator():
	if(state in ["wonFight", "gave_pill", "swallowed_pill"]):
		return "keerifox"
	else:
		return "Rahi"
