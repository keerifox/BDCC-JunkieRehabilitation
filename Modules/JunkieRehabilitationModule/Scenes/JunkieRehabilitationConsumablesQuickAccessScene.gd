extends "res://Modules/JunkieRehabilitationModule/Scenes/Overwrites/DrugDenEncounterTemplateScene.gd"

func _init():
	sceneID = "JunkieRehabilitationConsumablesQuickAccessScene"

func _reactInit():
	setState("consumables_quick_access")

func _run():
	if(state == "consumables_quick_access"):
		playAnimation(StageScene.Solo, "stand")

		var pcPersonality:Personality = GM.pc.getPersonality()
		var pcPersonalitySubbyScore:float = pcPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
		var pcIsDommy:bool = (pcPersonalitySubbyScore < -0.4)
		var pcIsSubby:bool = (pcPersonalitySubbyScore > 0.4)
		var pcIsSwitchy:bool = (!pcIsDommy && !pcIsSubby)

		var pcFetishHolder:FetishHolder = GM.pc.getFetishHolder()
		var pcInterestInOralSexGiving:float = pcFetishHolder.scoreFetishMax({ Fetish.OralSexGiving: 1.0 })
		var pcLikesOralSexGiving:bool = (pcInterestInOralSexGiving >= 0.5)
		var pcInterestInLactation:float = pcFetishHolder.scoreFetishMax({ Fetish.Lactation: 1.0 })
		var pcLikesLactation:bool = (pcInterestInLactation >= 0.5)
		var pcInterestInDoingStuffToButts:float = pcFetishHolder.scoreFetishMax({ Fetish.AnalSexGiving: 1.0, Fetish.RimmingGiving: 1.0 })
		var pcLikesDoingStuffToButts:bool = (pcInterestInDoingStuffToButts >= 0.5)
		var pcInterestInStuffBeingDoneToTheirButt:float = pcFetishHolder.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0, Fetish.RimmingReceiving: 1.0 })
		var pcLikesStuffBeingDoneToTheirButt:bool = (pcInterestInStuffBeingDoneToTheirButt >= 0.5)

		var pcPainLevel:float = GM.pc.getPainLevel()
		var pcLustLevel:float = GM.pc.getLustLevel()
		var pcStaminaLevel:float = GM.pc.getStaminaLevel()

		saynn("You examine various consumables in your possession, wondering whether to use any now, or to save them for later..")

		var possibleLines:Array = []

		if(pcLustLevel > 0.7):
			var possibleLines_lust_part1:Array = [
				"You are so incredibly pent up right now..",
				"You are so horny right now..",
				"You're feeling so damn aroused..",
			]

			if( GM.pc.hasBodypart(BodypartSlot.Penis) ):
				possibleLines_lust_part1.append_array([
					"You keep leaking pre..",
					"Your {pc.penisDesc} cock is throbbing so much..",
					"Your {pc.penisDesc} member is really hard right now..",
				])

			if( RNG.chance(10) ):
				possibleLines_lust_part1.append( RNG.pick([
					"Guh.. F-Fuckhhff,,.",
					"Hhhffh,,.",
					"Mmmfhfhhfh,,..",
					"Nnnhfhhhhh..",
				]) )

			var possibleLines_lust_part2:Array = [
				(
						RNG.pick([
							"At this rate, it'll only take one",
							"It wouldn't take more than a single",
						])
					+ " "
					+ (
							(
									RNG.pick(["brush", "rub", "touch"])
								+ " against"
							)
						if( GM.pc.isBlindfolded() || RNG.chance(60) )
						else "glance at"
					)
					+ " someone's "
					+ (
							RNG.pick([
								"inviting tailhole",
								"raised tail",
							])
						if( pcLikesDoingStuffToButts && RNG.chance(60) )
						else (
								RNG.pick(["alluring", "luscious"])
							+ " "
							+ RNG.pick(["body", "figure", "thighs"])
						)
					)
					+ " before you fully "
					+ RNG.pick(["give in", "submit"])
					+ " to your "
					+ RNG.pick(["cravings", "desires", "instincts"])
					+ ".."
				),
			]

			if(pcLikesOralSexGiving):
				possibleLines_lust_part2.append( RNG.pick([
					"Perhaps getting down to the level of someone's underwear would be a good start..",
					"With how much you're craving to tongue and suck through lewd bits.. You might just do that if invited to..",
					"You'd love to make good use of your lips and tongue..",
				]) )

			if(pcLikesLactation):
				var possibleLines_lust_part2_lactation:Array = [
					( "You could really use some "+ RNG.pick(["boobs", "breasts", "milkers"]) +" in your face.." ),
					( "What if there's someone here who will make you "+ RNG.pick(["suck", "suck at", "suck onto"]) +" their "+ RNG.pick(["boobs", "breasts", "milkers", "nipples"]) +".. What then.." ),
				]

				if( GM.pc.hasNonFlatBreasts() ):
					possibleLines_lust_part2_lactation.append_array([
						( "Someone should give your "+ RNG.pick(["boobs", "breasts", "milkers"]) +" a tight squeeze.." ),
						( "Someone should rub "+ RNG.pickWeightedPairs([ ["against", 0.5], ["into", 1.0], ["their face into", 0.5], ["their muzzle into", 0.5], ["themselves against", 0.5] ]) +" your "+ RNG.pick(["boobs", "breasts", "milkers"]) +".." ),
						( "You're willing to bet someone here would "+ RNG.pick(["suck", "suck at", "suck onto"]) +" your "+ RNG.pick(["boobs", "breasts", "milkers", "nipples"]) +" really good.." ),
					])

				possibleLines_lust_part2.append( RNG.pick(possibleLines_lust_part2_lactation) )

			if( GM.pc.hasBodypart(BodypartSlot.Penis) ):
				possibleLines_lust_part2.append_array([
					(
							"You might "
						+ RNG.pick(["cum", "end up making a large mess", "paint your surroundings with sticky seed"])
						+ " from just the "
						+ RNG.pick([
							"animations before your eyes",
							"images in your head",
							"visions in your mind"
						])
						+ ".."
					),
				])

			if(pcIsDommy || pcIsSwitchy):
				possibleLines_lust_part2.append_array([
					( "The thought of someone else using you is "+ ( "unusually" if( pcIsDommy && RNG.chance(80) ) else "really" ) +" tempting.." ),
					"You wouldn't even care about being the one in control..",
				])

			if(!pcIsDommy):
				possibleLines_lust_part2.append_array([
					"Someone should make good use of you..",
					"You should submit to the first creature you encounter.. They'll know how to make you feel good..",
				])

			if(pcIsSwitchy):
				possibleLines_lust_part2.append_array([
					(
							"You're unsure if you "
						+ RNG.pick(["crave", "desire", "want", "wish"])
						+ " "
						+ RNG.pick([
							"to be used like a toy, or to have one all to yourself",
							"to knock someone over, or to be pinned into the nearest wall",
							"to press a critter tight into the ground, or to be in their place",
						])
						+ ".. "
						+ RNG.pickWeightedPairs([
							["Do you even need to choose..", 1.0],
							["Have someone make the choice for you..", 1.0],
							[
								(
										RNG.pick(["Maybe", "Perhaps"])
									+ " "
									+ RNG.pick(["both", "the former", "the latter"])
									+ ".."
								),
								2.0
							],
							["Which one first..", 1.0],
						])
					),
				])
			elif(pcIsSubby):
				possibleLines_lust_part2.append_array([
					(
							RNG.pick([
								"At this rate",
								"If this keeps up",
								"Unless you do something about it now",
							])
						+ ", you'll "
						+ (
								(
										"lift your tail"
									if( GM.pc.hasTail() )
									else "bend over"
								)
							if( pcLikesStuffBeingDoneToTheirButt && RNG.chance(80) )
							else "get on your knees"
						)
						+ (
								""
							if(pcLustLevel >= 1.0)
							else " almost"
						)
						+ " as soon as you stumble into someone.."
					),
					"Such a good pet..",
					"You could be a really good playtoy for that figure in the distance..",
				])

			possibleLines.append(
					RNG.pick(possibleLines_lust_part1)
				+ (
						(
								" "
							+ RNG.pick(possibleLines_lust_part2)
						)
					if( possibleLines_lust_part2.size() >= 1 )
					else ""
				)
			)
		else:
			if(pcPainLevel > 0.7):
				var pcPainLevelIsCritical:bool = (pcPainLevel > 0.9)

				possibleLines.append( RNG.pick([
					( "Everything "+ ( "fucking" if(pcPainLevelIsCritical) else "kind of" ) +" hurts.." ),
					( "Hopefully you've got something to "+ ( "at least suppress" if(pcPainLevelIsCritical) else "deal with" ) +" the pain.." ),
					( "The pain is "+ ( "way" if(pcPainLevelIsCritical) else "a little" ) +" too much.." ),
					( "You miss not being under "+ ( "severe" if(pcPainLevelIsCritical) else RNG.pick(["intense", "unmanageable"]) ) +" pain all of the time.." ),
					( "Your "+ RNG.pick(["bones", "limbs"]) +" "+ ( "are in so much pain right now" if(pcPainLevelIsCritical) else "hurt" ) +".." ),
				]) )

			if(pcStaminaLevel < 0.3):
				var pcStaminaLevelIsCritical:bool = (pcStaminaLevel < 0.1)

				possibleLines.append( RNG.pick([
					(
							"An energy drink could really "
						+ (
								"help with"
							if(pcStaminaLevelIsCritical)
							else "quench"
						)
						+ " your thirst right now.."
						+ (
								" One kind of thirst anyway.."
							if(pcLustLevel > 0.3)
							else ""
						)
					),
					( "There's "+ ( "barely any" if(pcStaminaLevelIsCritical) else "very little" ) +" energy left in you.." ),
					(
							"You could use a soft bed right now.."
						+ (
								" Or two.."
							if(pcStaminaLevelIsCritical)
							else ""
						)
					),
					( "You feel "+ ( "completely" if(pcStaminaLevelIsCritical) else "rather" ) +" exhausted.." ),
					( "You feel "+ ( "so damn" if(pcStaminaLevelIsCritical) else "so" ) +" tired.." ),
					(
							"Your legs barely allow you to move forward.."
						+ (
								" Might have to switch to all fours soon.."
							if(pcStaminaLevelIsCritical)
							else ""
						)
					),
				]) )

			if( possibleLines.size() == 0 ):
				if(pcPainLevel > 0.5):
					possibleLines.append( RNG.pick([
						( "Ambient pain engulfs your "+ RNG.pick(["upper", "lower"]) +" body.." ),
						"There were days you felt more comfortable..",
						"You feel mild pain across your whole body..",
						"You've been in better shape..",
					]) )

				if(pcStaminaLevel < 0.5):
					possibleLines.append( RNG.pick([
						"It's a little difficult to focus without a good rest..",
						"Might need to lay down soon..",
						"You can't seem to focus as easily anymore..",
						"You could use a little bit of rest..",
					]) )

		if( possibleLines.size() >= 1 ):
			saynn( RNG.pick(possibleLines) )

		addButton("Continue", "Enough using items.", "endthescene")
		consumables_addButtons()

	encounter_run()
	
func _react(_action: String, _args):
	if(_action == "endthescene"):
		endScene()
		return
	if(encounter_react(_action, _args)):
		return
	
	setState(_action)
