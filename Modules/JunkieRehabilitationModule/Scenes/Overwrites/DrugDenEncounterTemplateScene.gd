extends SceneBase

const RehabilitatedJunkieGenerator = preload("res://Modules/JunkieRehabilitationModule/Characters/Dynamic/Generator/RehabilitatedJunkieGenerator.gd")

var npcID:String = ""
var wonState:String = ""
var expWin:int = 50

func _init():
	sceneID = "DrugDenEncounterTemplateScene"

func generateJunkieNPCID(_isBoss:bool = false) -> String:
	var theGenerator := DrugDenJunkieGenerator.new()
	var theChar:BaseCharacter = theGenerator.generate({
		NpcGen.Temporary: true,
		NpcGen.IsBoss: _isBoss,
	})
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
		var gotUncon:bool = false
		var sexResult:Dictionary = _result[0]
		if(sexResult.has("subs")):
			var subs:Dictionary = sexResult["subs"]
			if(subs.has("pc")):
				var info:Dictionary = subs["pc"]
				if(info.has("isUnconscious") && info["isUnconscious"]):
					gotUncon = true
		
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

		saynn("You produce a \"JunkieBeMine\" pill and force them to swallow it.")
		
		var possible:Array = [
			"No.. What have you-",
			"F- Fucker.. What are you-",
			"I am not done with you yet.. Fuck..",
			"Get your hand- Fshkf..",
			"How about you shove this up your-",
			"I will mess you up- mffmfh..",
		]
		
		if(sceneID == "DrugDenEncounterBossScene"):
			possible.append_array([
				"Whore. You don't deserve even a fraction of this lab.. What are y-",
				"You think you got this all figured out? My thugs will- The fuck are yo..",
				"You're still an amateur that would waste this state-of-the-art equipment to make a fucking painkil- Get your dirty hands off me! Mfhhsfh-"
			])
		else:
			possible.append_array([
				"So nice of you to share~.",
				"Oooh new product! Gimme-ahff~",
			])
		
		saynn("[say=npc]"+RNG.pick(possible)+"[/say]")

		addButton("Continue", "See what happens next", "swallowed_pill")

	if(state == "swallowed_pill"):
		playAnimation(StageScene.Sleeping, "sleep", {pc=npcID})

		saynn( RNG.pick([
			"Weakened after the fight, {npc.name} falls onto {npc.his} spine, slipping into slumber.",
			"There is no stamina left in {npc.name} to resist, and {npc.he} {npc.youVerb('collapse')} on {npc.his} side, beside you.",
			"No more words leave {npc.nameS} mouth. For a brief moment, {npc.he} {npc.youVerb('stare')} at you with an alert expression, then.. {npc.youVerb('doze')} off.",
		]) )

		saynn("[say=pc]"+RNG.pick([
			"Let's hope this works..",
			"That should take care of your addiction..",
			"Hmph. Maybe you are worth surrendering to..",
			"I'm a little selfish, huh..",
			"Sorry, can't afford to lose you to this place.",
			"I hope we meet again.",
			"Such a hot thing.",
			"What a charming thing.",
		])+"[/say]")

		addMessage("{npc.name} can now be found around the cellblock.")

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
		setState("gave_pill")
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
		runScene("GenericSexScene", [npcID, "pc", SexType.DefaultSex, {subMustGoUnconscious=true}], "defeated_sex")
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
	
	return data
	
func loadData(data):
	.loadData(data)
	
	npcID = SAVE.loadVar(data, "npcID", "")

func getSceneCreator():
	if(state in ["wonFight", "gave_pill", "swallowed_pill"]):
		return "keerifox"
	else:
		return "Rahi"
