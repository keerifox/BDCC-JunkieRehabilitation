extends SceneBase

const RehabilitatedJunkieGenerator = preload("res://Modules/JunkieRehabilitationModule/Characters/Dynamic/Generator/RehabilitatedJunkieGenerator.gd")

var npcID:String = ""
var hasRecognizedPill:bool = false
var wonState:String = ""
var expWin:int = 50

var sideEffects_statusLines:Array = []

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
	if( (theChar.npcPronounsGender == Gender.Other) && RNG.chance(50) ):
		theChar.npcGender = Gender.Other

	var theID:String = theChar.id
	
	return theID

func rehabilitateJunkie() -> DynamicCharacter:
	var junkieChar = getCharacter(npcID)
	junkieChar.setTemporary(false)

	var generator = RehabilitatedJunkieGenerator.new()
	var inmateChar:DynamicCharacter = generator.process(junkieChar)
	var isInmateIdentityMachine:bool = false

	if(inmateChar.npcGender == Gender.Other):
		var identities_machine:Array = ["Machine"]
		var identities:Array = [
			RNG.pick(["Creature", "Critter"]),
			"Kin",
			RNG.pick(identities_machine),
			RNG.pick(["Plush", "Toy"])
		]
		var inmateIdentity:String = RNG.pick(identities)
		isInmateIdentityMachine = (inmateIdentity in identities_machine)
		inmateChar.npcSmallDescription = Util.getSpeciesName(inmateChar.npcSpecies) +". "+ inmateIdentity +"."

	var customNameOrEmpty:String = ""

	var junkieRehabilitationModule = GlobalRegistry.getModule("JunkieRehabilitationModule")
	if(isInmateIdentityMachine):
		customNameOrEmpty = junkieRehabilitationModule.pickCustomName_machine()
	else:
		customNameOrEmpty = junkieRehabilitationModule.pickCustomName(inmateChar.npcPronounsGender)
		
	if( !customNameOrEmpty.empty() ):
		inmateChar.npcName = customNameOrEmpty

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

func sideEffects_getPotentialPersonalityChanges(inmateChar:BaseCharacter, valueAdd:float) -> Array:
	var potentialPersonalityChanges:Array = []

	var inmatePersonality:Personality = inmateChar.getPersonality()
	var pcPersonality:Personality = GM.pc.getPersonality()
	var pcPersonalitySubbyScore:float = pcPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
	var pcIsDommy:bool = (pcPersonalitySubbyScore < -0.4)
	var pcIsSubby:bool = (pcPersonalitySubbyScore > 0.4)

	var potentialPersonalityChangesIncludingIneffective:Array = [
		{
			personalityStat = PersonalityStat.Mean,
			valueAdd = -valueAdd,
			becameWhat = "more mean",
		}, {
			personalityStat = PersonalityStat.Brat,
			valueAdd = -valueAdd,
			becameWhat = "more bratty",
		}, {
			personalityStat = PersonalityStat.Naive,
			valueAdd = valueAdd,
			becameWhat = "more perceptive",
			shouldInvertShownSign = true,
		}
	]

	if(pcIsDommy):
		potentialPersonalityChangesIncludingIneffective.append({
			personalityStat = PersonalityStat.Subby,
			valueAdd = valueAdd,
			becameWhat = "less subby",
		})
	elif(pcIsSubby):
		potentialPersonalityChangesIncludingIneffective.append({
			personalityStat = PersonalityStat.Subby,
			valueAdd = -valueAdd,
			becameWhat = "less dommy",
			shouldInvertShownSign = true,
		})

	for changeData in potentialPersonalityChangesIncludingIneffective:
		var valueBefore:float = inmatePersonality.getStat(changeData.personalityStat)
		var valueAfter:float = clamp( (valueBefore + changeData.valueAdd), -1.0, 1.0 )
		var valueAddClamped:float = (valueAfter - valueBefore)
		var valueAddClampedAbsolute:float = abs(valueAddClamped)
		var isIneffective:bool = ( valueAddClampedAbsolute < ( 0.7 * abs(changeData.valueAdd) ) )

		if(isIneffective):
			continue

		changeData.valueAddClamped = valueAddClamped
		potentialPersonalityChanges.append(changeData)

	if(	potentialPersonalityChanges.size() == 0 ):
		potentialPersonalityChanges.append({
			personalityStat = PersonalityStat.Impatient,
			valueAdd = -valueAdd,
			valueAddClamped = -valueAdd,
			becameWhat = "more impatient",
		})

	return potentialPersonalityChanges

func sideEffects_getPotentialFetishChanges(inmateChar:BaseCharacter, valueAdd:float) -> Array:
	var potentialFetishChanges:Array = []

	var inmatePersonality:Personality = inmateChar.getPersonality()
	var inmatePersonalityMeanScore:float = inmatePersonality.personalityScoreMax({ PersonalityStat.Mean: 1.0 })
	var inmateIsMean:bool = (inmatePersonalityMeanScore > 0.4)
	var inmatePersonalitySubbyScore:float = inmatePersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
	var inmateIsDommy:bool = (inmatePersonalitySubbyScore < -0.4)
	var inmateIsSubby:bool = (inmatePersonalitySubbyScore > 0.4)
	#var inmateIsSwitchy:bool = (!inmateIsDommy && !inmateIsSubby)

	var pcPersonality:Personality = GM.pc.getPersonality()
	var pcPersonalityMeanScore:float = pcPersonality.personalityScoreMax({ PersonalityStat.Mean: 1.0 })
	var pcIsMean:bool = (pcPersonalityMeanScore > 0.4)
	var pcPersonalitySubbyScore:float = pcPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
	var pcIsDommy:bool = (pcPersonalitySubbyScore < -0.4)
	var pcIsSubby:bool = (pcPersonalitySubbyScore > 0.4)
	#var pcIsSwitchy:bool = (!pcIsDommy && !pcIsSubby)

	var pcPreferredSubbyType:String = (
			"dom"
		if(pcIsSubby)
		else (
				RNG.pickWeightedPairs([
					["dom", 1.0],
					["switch", 2.0],
					["sub", 1.0],
				])
			if(!pcIsDommy)
			else "sub"
		)
	)

	var pcHasNonFlatBreasts:bool = GM.pc.hasNonFlatBreasts()
	var pcHasPenis:bool = GM.pc.hasBodypart(BodypartSlot.Penis)
	var pcHasVagina:bool = GM.pc.hasBodypart(BodypartSlot.Vagina)
	var pcHighlightedLewdBits:String = "fluff"
	if(pcHasPenis && pcHasVagina):
		pcHighlightedLewdBits = RNG.pickWeightedPairs([
			["penis", 2.0],
			["both", 3.0],
			["vagina", 2.0],
			["fluff", 1.0],
		])
	elif(pcHasPenis && !pcHasVagina):
		pcHighlightedLewdBits = "penis"
	elif(!pcHasPenis && pcHasVagina):
		pcHighlightedLewdBits = "vagina"

	var inmateHasNonFlatBreasts:bool = inmateChar.hasNonFlatBreasts()
	var inmateHasPenis:bool = inmateChar.hasBodypart(BodypartSlot.Penis)
	var inmateHasVagina:bool = inmateChar.hasBodypart(BodypartSlot.Vagina)
	var inmateHighlightedLewdBits:String = "fluff"
	if(inmateHasPenis && inmateHasVagina):
		inmateHighlightedLewdBits = RNG.pickWeightedPairs([
			["penis", 2.0],
			["both", 3.0],
			["vagina", 2.0],
			["fluff", 1.0],
		])
	elif(inmateHasPenis && !inmateHasVagina):
		inmateHighlightedLewdBits = "penis"
	elif(!inmateHasPenis && inmateHasVagina):
		inmateHighlightedLewdBits = "vagina"

	var npc_they:String = inmateChar.heShe()
	var npc_hisHerOwnIts:String = ( "own" if(npc_they == "they") else "{npc.his}" )
	var npc_feline_MAYBE:String = sideEffects_getIncompleteSpeciesFullName( inmateChar.getSpecies() ).to_lower()
	var npc_tail_or_butt:String = "tail" if( inmateChar.hasTail() ) else "butt"

	var inmateFetishHolder:FetishHolder = inmateChar.getFetishHolder()
	var pcFetishHolder:FetishHolder = GM.pc.getFetishHolder()

	var inmateInterestInBeingBred:float = inmateFetishHolder.scoreFetishMax({ Fetish.BeingBred: 1.0 })
	var inmateLikesBeingBred:bool = (inmateInterestInBeingBred >= 0.5)
	var inmateInterestInLactation:float = inmateFetishHolder.scoreFetishMax({ Fetish.Lactation: 1.0 })
	var inmateLikesLactation:bool = (inmateInterestInLactation >= 0.5)
	var inmateInterestInBeingPenetrated:float = inmateFetishHolder.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0, Fetish.VaginalSexReceiving: 1.0 })
	var inmateLikesBeingPenetrated:bool = (inmateInterestInBeingPenetrated >= 0.5)
	var inmateInterestInPenetratingOthers:float = inmateFetishHolder.scoreFetishMax({ Fetish.AnalSexGiving: 1.0, Fetish.VaginalSexGiving: 1.0 })
	var inmateLikesPenetratingOthers:bool = (inmateInterestInPenetratingOthers >= 0.5)
	var inmateInterestInBondage:float = inmateFetishHolder.scoreFetishMax({ Fetish.Bondage: 1.0 })
	var inmateLikesBondage:bool = (inmateInterestInBondage >= 0.5)

	var potentialFetishChangesIncludingIneffective:Array = [
		{
			fetishPair = [Fetish.AnalSexGiving, Fetish.AnalSexReceiving],
			interestInWhatPair = [
				RNG.pick([
					"creaming the butt of everyone who raises their tail to invite {npc.him} in",
					( "bending others over to eagerly stuff their tailholes, "+ ( "pleased" if(valueAdd > 0.0) else "displeased" ) +" with how easily they give into it" ),
					(
							"reaching around to lustfully run {npc.his} paws through a critter's "
						+ ( "round breasts" if(pcHasNonFlatBreasts) else "soft chest" )
						+ " and squishy belly, while needily fucking {npc.his} plaything from behind"
					),
					"stuffing tailholes of critters tightly pressed into a wall, with their legs trembling",
					"stumbling upon critters in very vulnerable poses pretending to be stuck, and making good use of their tailholes",
					(
							"watching creatures helplessly wiggle their legs, as their whole body is suspended in air, tailhole snugly fit with "
						+ (
								"their captor's"
							if(npc_they == "they")
							else "{npc.his}"
						)
						+ " cock"
					),
				]),
				RNG.pick([
					"being buttfucked in the shower as {npc.his} legs tremble and {npc.he} {npc.verb('struggle')} to wash {npc.his} fur",
					"being lovingly fucked in the butt, while two paws needily grab onto {npc.his} delicious cheeks",
					RNG.pickWeightedPairs([
						[
							( "enthusiastically riding a critter's {pc.penisDesc} member for {npc.his} own pleasure, taking them deeply with "+ npc_hisHerOwnIts +" tailhole" ),
							( 0.0 if(inmateIsSubby) else 1.0 ),
						],
						[
							"being forced on all fours by a hindpaw lightly pressing at {npc.his} spine, leashed and eagerly fucked from behind",
							( 0.0 if(inmateIsDommy) else 1.0 ),
						],
					]),
					"having others cream {npc.his} butt in innumerable alluring poses",
					"invitingly bending over a piece of furniture, for others to take {npc.him} from behind",
					RNG.pickWeightedPairs([
						[
							"positioning {npc.himself} above another critter's {pc.penisDesc} cock as it's leaking pre, using it quite eagerly, for own pleasure",
							( 0.0 if(inmateIsSubby) else 1.0 ),
						],
						[
							"being needily dry humped for hours, feeling at ease, comfortable and relaxed, knowing {npc.theyre} valued and desired, accepting {npc.his} predicament, even if {npc.he} still low-key {npc.verb('crave')} to eventually be buttstuffed",
							( 0.0 if(inmateIsDommy) else 1.0 ),
						],
					]),
					( "raising {npc.his} "+ npc_tail_or_butt +" for others to stuff {npc.him} full for hours on end" ),
				])
			],
			requirementsPair = [
				["pcHasAnus"],
				["inmateHasAnus"],
			],
		},
		{
			fetish = Fetish.Bodywritings,
			interestInWhat = {
				dom = RNG.pick([
					"expressing {npc.his} creativity with crayons and willing critters' bodies",
					(
								"making others {npc.his} canvas, "
						+ (
								"often inviting artist friends to produce the prettiest paintings"
							if( GM.main.encounterSettings.shouldSubThreesomesBeEnabled() && RNG.chance(80) )
							else "no matter how self-conscious {npc.he} {npc.is} about own art"
						)
					),
					"writing naughty words all over soft spots of other critters' bodies",
				]),
				switch = RNG.pick([
					"carrying a set of crayons and using every opportunity to draw on each other's bodies",
					"inking one another with naughty drawings and writings",
					"participating in art trades involving each other's exposed bodies",
				]),
				sub = RNG.pick([
					"becoming a canvas for others to draw on and spending the following days to discover new drawings across {npc.his} body that {npc.he} {npc.wasnt} aware {npc.he} had",
					"being drawn all over and excitedly displaying {npc.his} newly acquired art to all of {npc.his} friends",
					"being someone's canvas and unwillingly agreeing to each adjective that was written over {npc.him}",
				]),
			}[pcPreferredSubbyType]
		},
		{
			fetishPair = [Fetish.Breeding, Fetish.BeingBred],
			interestInWhatPair = [
				RNG.pick([
					"continuing to breed others even after noticeable amounts of cum would begin to drip down from their holes",
					(
							"getting other critters pregnant after having teased them to such extent that they were pleading "
						+ (
								""
							if(npc_they == "they")
							else "{npc.him} "
						)
						+ "to impregnate them"
					),
					"leaving everyone with a larger and more round belly than when {npc.he} found them",
					"pinning others down beneath {npc.himself} then needily breeding them",
					"repeatedly trying to impregnate others against all and any odds",
					RNG.pickWeightedPairs([
						[
							(
									"seeing other critters bend themselves over in front"
								+ (
										""
									if(npc_they == "they")
									else " of {npc.him}"
								)
								+ ", then eagerly impregnating them"
							),
							( 0.0 if(inmateIsSubby) else 1.0 ),
						],
						[
							"being someone's breeding toy, always one grab away from finding {npc.himself} beneath another critter that wished to take {npc.him} for a ride",
							( 0.0 if(inmateIsDommy) else 1.0 ),
						],
					]),
				]),
				RNG.pick([
					"being bred needily, as {npc.he} {npc.verb('daydream')} about having a large round belly that anyone would be welcome to rub and squeeze at",
					"being filled to the brim with seed so fertile that no species incompatibility or contraceptives could prevent {npc.his} pregnancy",
					"getting impregnated as a result of merely walking into someone very needy",
					"having a huge impregnated belly and offering the responsible critter to be as lewd with it as they want to be, at any time",
					"having a round rose-tinted belly to show for each time {npc.he}'d been creamed full of fertile cum",
				])
			],
		},
		{
			fetishPair = [Fetish.FeetplayGiving, Fetish.FeetplayReceiving],
			interestInWhatPair = [
				RNG.pick([
					(
							"delivering delicate yet immodest pawjobs"
						+ RNG.pickWeightedPairs([
							["", 80.0],
							[" in an otherwise oversaturated market", 5.0],
							[" with the promise of a low-stress environment, striking a good hindpaw-handpaw balance", 5.0],
							[" with perks that include high flexibility, free snacks, and a pledge to getting others off on their days off", 5.0],
							[", while respectful of any unions that {npc.his} subjects might be members of", 5.0],
						])
					),
					"indulging someone's craving for a pair of paws repeatedly running through their face as they helplessly try to lick back at them",
					(
							( "harshly" if(inmateIsMean) else "gently" )
						+ " brushing {npc.his} paws around and over someone's most sensitive areas, "
						+ (
								"occasionally lightly slapping, and making use of {npc.his} tongue"
							if( inmateIsMean || RNG.chance(40) )
							else "often adding a pleasuring sensation of {npc.his} lips"
						)
					),
					"rubbing hindpaws all over creatures as they lay helpless on the ground, tied in alluring shibari patterns",
				]),
				RNG.pick([
					"being intimately rubbed all over with both hind- and handpaws",
					"being lightly pinned into the ground by other critters' hindpaws",
					"being smothered with paws, almost uncomfortably so, squeaking and squirming underneath yet begging the critter to continue",
					"laying on the ground, caught beneath other critters' hindpaws",
					"licking through the pawpads of someone else's paws as they're tightly pressed into {npc.his} face",
				])
			],
		},
		{
			fetishPair = [Fetish.HypnosisHypnotist, Fetish.HypnosisSubject],
			interestInWhatPair = [
				RNG.pick([
					(
							"locking eyes with another critter until they feel compelled to obey "
						+ RNG.pick([
							(
									"each and every endearing instruction"
								if(npc_they == "they")
								else RNG.pick([
									"{npc.his} each and every endearing instruction",
									"every word {npc.he} {npc.verb('say')}",
								])
							),
							(
									"every quietly whispered word"
								if(npc_they == "they")
								else RNG.pick([
									"{npc.his} every quietly whispered word",
									"every word leaving {npc.his} mouth",
								])
							)
						])
					),
					(
							"whispering into other critters' ears, in a peculiar, unusually captivating way, that would make "
						+ (
								"{npc.his} subjects"
							if(npc_they == "they")
							else "them"
						)	
						+ " disinclined to turn down {npc.his} requests, no matter how much "
						+ (
								"they'd ask"
							if(npc_they == "they")
							else RNG.pick([
								"{npc.he}'d ask of them",
								"is asked of them",
							])
						)
					),
				]),
				RNG.pick([
					(
							"being under another creature's spell, unwilling to refuse "
						+ (
								(
										"even their most "
									+ RNG.pick([ "demanding", "immodest", "self-indulgent" ])
									+ " requests"
								)
							if( (npc_they == "they") || RNG.chance(60) )
							else "anything that they ask of {npc.him}"
						)
					),
					(
							"noticing that someone's attempt to force a hypnovisor on {npc.him}, with the intention to make {npc.him} submissive and breedable, has yielded no changes as {npc.he} {npc.was} both of these things already"
						if(inmateIsSubby && inmateLikesBeingBred)
						else (
							(
									(
											"becoming submissive and breedable within mere seconds"
										if(!inmateIsSubby && !inmateLikesBeingBred)
										else (
												"having already been very submissive, becoming quite breedable too, within mere seconds"
											if(inmateIsSubby)
											else "having already been very breedable, becoming increasingly submissive too, within mere seconds"
										)
									)
								+ " of being sneaked up on and put a hypnovisor on"
							)
						)
					),
					{
						text = "pretty colorful spirals which span {npc.his} vision and swirl increasingly more gorgeous with each time {npc.he} {npc.verb('obey')} someone's command without any hesitation",
						isPlural = true,
					},
				])
			],
		},
		{
			fetish = Fetish.Lactation,
			interestInWhat = {
				dom = RNG.pick([
					(
							(
									"backing others into a corner and pressing {npc.his} heavy milkers "
								+ RNG.pick(["against", "into"])
								+ " "
								+ (
										"the critter's"
									if(npc_they == "they")
									else "their"
								)
								+ " flustered face"
							)
						if(inmateHasNonFlatBreasts)
						else "backing others into a corner, then leaning in to strip their clothes and indulgently explore the curves of their breasts"
					),
					( "burying "+ npc_hisHerOwnIts +" face between a pair of sizeable breasts, fervently using them for own pleasure" ),
					"groping and fondling through someone's breasts until they begin to drip with more and more milk",
				]),
				switch = RNG.pick([
					(
							"catching a needy creature and taking turns tasting each other's delicious breast milk"
						if(inmateHasNonFlatBreasts && pcHasNonFlatBreasts)
						else "catching a needy critter and taking turns lapping at one another's aroused nipples"
					),
					(
							"using {npc.his} lips to milk breasts of other critters, and having {npc.his} own milkers used the same way"
						if(inmateHasNonFlatBreasts)
						else "using {npc.his} lips to milk breasts of other critters, while dripping with a different kind of milk"
					),
				]),
				sub = RNG.pick([
					(
							"having boobs shoved into {npc.his} face"
						+ (
								", even when {npc.he} would be trying to concentrate on something important, perhaps especially when"
							if(valueAdd > 0.0)
							else " when {npc.he} would be trying to concentrate on something important"
						)
					),
					(
							"having {npc.his} boobs obsessively played with, and precious milk gradually leaking out of them"
						if(inmateHasNonFlatBreasts)
						else "having {npc.his} nipples obsessively played with, on a mere promise of delicious milk"
					),
				]),
			}[pcPreferredSubbyType]
		},
		{
			fetishPair = [Fetish.OralSexReceiving, Fetish.OralSexGiving],
			interestInWhatPair = [
				RNG.pick([
					(
							"having someone lap and tongue through "
						+ {
							penis = "{npc.his} tempting {npc.penisDesc} shaft",
							both = "{npc.his} erect {npc.penisDesc} cock and {npc.his} leaky pussy",
							vagina = "the folds of {npc.his} needy kitty",
							fluff = "{npc.his} fluffy crotch",
						}[inmateHighlightedLewdBits]
					),
					(
							(
									"seeing a dominant critter lower themselves to the height of {npc.his} waist and "
								if(inmateIsSubby)
								else "commanding another critter to get on their knees and obediently "
							)
						+ {
							penis = "suck through {npc.his} aroused {npc.penisDesc} shaft",
							both = "pleasure both {npc.his} kitty and {npc.penisDesc} member",
							vagina = "work their tongue at {npc.his} wet pussy",
							fluff = "lap at {npc.his} fluffy crotch",
						}[inmateHighlightedLewdBits]
					),
				]),
				RNG.pick([
					(
							(
									"being ordered to slide"
								if(inmateIsSubby)
								else "sliding"
							)
						+ " someone's underwear down to their ankles"
						+ (
								", as they demand to take"
							if(inmateIsSubby)
							else ", then taking"
						)
						+ " good care of "
						+ {
							penis = "their delicious cock",
							both = "both of their lewd bits",
							vagina = "their wet pussy",
							fluff = "their fluffy crotch",
						}[pcHighlightedLewdBits]
					),
					(
							"having a critter's thighs tightly pressed at both of {npc.his} face cheeks"
						+ {
							penis = " while a delicious {pc.penisDesc} bone reaches deep into {npc.his} mouth",
							both = " while smothered by all kinds of lewd bits",
							vagina = (
									" as {npc.theyre} "
								+ ( "helplessly" if(inmateIsSubby) else "eagerly" )
								+ " lapping at {npc.his} "
								+ RNG.pickWeightedPairs([
									[
										"submissive's",
										( 0.0 if(inmateIsSubby) else 1.0 ),
									],
									[
										"dominant's",
										( 0.0 if(inmateIsDommy) else 1.0 ),
									],
								])
								+ " pussy"
							),
							fluff = ", making {npc.him} feel particularly needy for the fluffy crotch that's directly in {npc.his} face",
						}[pcHighlightedLewdBits]
					),
					(
							"leaving trails of saliva between {npc.his} lips and a critter's "
						+ {
							penis = "{pc.penisDesc} member as it's covered in ribbons of freshly produced cum",
							both = "most sensitive, intimate areas",
							vagina = "wet, welcoming pussy",
							fluff = "intimate, soaked fluff",
						}[pcHighlightedLewdBits]
					),
					RNG.pickWeightedPairs([
						[
							"skillfully using {npc.his} tongue and lips to send a submissive critter over the edge, savoring every drop of their cum",
							( 0.0 if(inmateIsSubby) else 1.0 ),
						],
						[
							(
									"being mouthfucked "
								+ (
										"through a ring gag that's difficult to take off"
									if( inmateLikesBondage && RNG.chance(70) )
									else "as both of {npc.his} wrists are held firmly with just one paw of a larger critter"
								)
							),
							( 0.0 if(inmateIsDommy) else 1.0 ),
						],
					])
				])
			],
		},
		{
			fetishPair = [Fetish.Rigging, Fetish.Bondage],
			interestInWhatPair = [
				RNG.pick([
					"forcing imaginary restraints upon critter's limbs, and getting them to act submissive with only a couple suggestive touches and a highly alluring presence",
					"locking bondage gear around other critters' luscious thighs",
					(
							"making bound toys out of other inmates and "
						+ (
								"teasing them for hours"
							if(inmateIsMean)
							else (
									"kissing {npc.his} way through exposed areas of "
								+ (
										"the critters'"
									if(npc_they == "they")
									else "their"
								)
								+ " bodies"
							)
						)
					),
					"putting column ties around willing critters' limbs",
					"shushing others by shoving a gag in the shape of a bone into their mouth",
					(
							"tying others up in alluring shibari floorwork, then teasing them with various gear that "
						+ (
								"they crave"
							if( (npc_they == "they") || RNG.chance(30) )
							else "{npc.he}'d like to see them wear"
						)
						+ " the most"
					),
				]),
				RNG.pick([
					"being all bark and no bite upon having a muzzle restraint forced over {npc.his} snout",
					( "being made into a rope "+ npc_feline_MAYBE +" by creatures that are good with knots" ),
					"being severely restricted in movement with every available restraint",
					( "enduring a numb feeling in "+ npc_hisHerOwnIts +" arms as they're bound behind {npc.his} back, leaving {npc.him} defenseless against roaming creatures that are eager to explore {npc.his} soft, exposed curves" ),
					( "feeling a cold sensation of metallic cuffs on {npc.his} ankles, "+ ( "and a pleasing" if(valueAdd > 0.0) else "finding pleasure in the" ) +" discomfort from the short chain that prevents {npc.him} from moving one hindpaw too far away from the other" ),
					"feeling bound and helpless from the amount of gear forced on {npc.him}",
					"having {npc.his} body adorned with more restraints than {npc.he} {npc.is} able to count",
					"having someone wrap {npc.him} in countless ribbons, like a present",
				])
			],
		},
		{
			fetishPair = [Fetish.RimmingGiving, Fetish.RimmingReceiving],
			interestInWhatPair = [
				RNG.pick([
					(
							(
									"sneaking up"
								if(inmateIsDommy)
								else "crawling on all fours"
							)
						+ " next to another critter's legs, and burying "
						+ npc_hisHerOwnIts
						+ " face in their "
						+ ( "" if(valueAdd > 0.0) else "typically " )
						+ "irresistable buns"
					),
					RNG.pickWeightedPairs([
						[
							( "sliding down someone's underwear, then moving "+ npc_hisHerOwnIts +" muzzle intimately close, kissing and lapping at their tailhole" ),
							( 0.0 if(inmateIsSubby) else 1.0 ),
						],
						[
							(
									"being forced to obediently tongue through a critter's tailhole"
								if(npc_they == "they")
								else "having another critter shove their tailhole into {npc.his} face, forcing {npc.him} to submissively tongue through it"
							),
							( 0.0 if(inmateIsDommy) else 1.0 ),
						],
					])
				]),
				RNG.pick([
					"alluringly undressing and spreading over an object, as an invitation for others to passionately lick through {npc.his} tailhole",
					RNG.pickWeightedPairs([
						[
							( "playfully grabbing another creature by the leash and pulling their "+ ( "fussy" if(pcIsMean) else "blushy" ) +" face into own tailhole" ),
							( 0.0 if(inmateIsSubby) else 1.0 ),
						],
						[
							"spreading {npc.his} legs over a bar counter and inviting another critter to destitutely eat {npc.him} out",
							( 0.0 if(inmateIsDommy) else 1.0 ),
						],
					])
				])
			],
			requirementsPair = [
				["pcHasAnus"],
				["inmateHasAnus"],
			],
		},
		{
			fetishPair = [Fetish.Sadism, Fetish.Masochism],
			interestInWhatPair = [
				RNG.pick([
					(
							"biting you in particular"
						if(valueAdd > 0.0)
						else (
								"pleasuring other critters with "
							+ npc_hisHerOwnIts
							+ " "
							+ ( "hurtful" if(inmateIsMean) else "tender" )
							+ " bites"
						)
					),
					(
							"covering a willing critter in "
						+ (
								"deep bitemarks"
							if(inmateIsMean)
							else "both bitemarks and lipstick marks"
						)
					),
					( "encountering soft tummy creatures and fantasizing of all the ways {npc.he}'d put "+ npc_hisHerOwnIts +" mouth on them" ),
					( "inflicting pain upon others, "+ ( "" if(valueAdd > 0.0) else "even " ) +"when it's what they crave the most" ),
					"leaving scratch marks all over a critter's curvy spine",
				]),
				RNG.pick([
					"being put through painful play sessions",
					"having another creature sink their teeth into {npc.him}",
					"inviting creatures with vampiric tendencies into own cell",
					"letting other critters decide which factors should set off {npc.his} shock collar, regardless if in an automated way or not",
					"\"misplacing\" a remote that allows other creatures to send jolting sensations through {npc.his} body",
				])
			],
		},
		{
			fetish = Fetish.SeedMilking,
			interestInWhat = {
				dom = RNG.pick([
					"being very handful with other creatures while ensuring that not a single drop of their delicious cum is lost",
					(
							"milking critters "
						+ (
								"not only for their breast milk, but also their precious cum"
							if(inmateLikesLactation)
							else "for their precious cum"
						)
					)
				]),
				switch = RNG.pick([
					"finding a critter to be excessively touchy with, mutually milking one another for precious drops of cum",
					(
							(
									"grabbing others for mutual touching,"
								if(inmateIsMean)
								else "snugging up to others"
							)
						+ " and taking care of every single drop of one another's bountiful cum"
					),
				]),
				sub = RNG.pick([
					"being touched all over, then delicately milked for {npc.his} cum",
					{
						text = (
								"toys that keep {npc.him} a continuously squirming mess as "
							+ (
									"precious cum is drained from"
								if( (npc_they == "they") || RNG.chance(30) )
								else "they milk precious cum out of"
							)
							+ " {npc.him}"
						),
						isPlural = true,
					},
				]),
			}[pcPreferredSubbyType]
		},
		{
			fetishPair = [Fetish.TFGiving, Fetish.TFReceiving],
			interestInWhatPair = [
				RNG.pick([
					"helping critters find new favorite shapes by letting them intimately try each and every one of them",
					"making exceptions to {npc.his} aspiration not to change anything in other creatures, when it's what is begged of {npc.him}",
					"molding others into shapes {npc.he} {npc.verb('love')} the most",
					"politely asking other critters whether they would indulge {npc.him} by shapeshifting into species that {npc.he} {npc.verb('drool')} the most for",
					"transforming critters with the goal to evoke most immense lustful sensations within them, as they're close and intimate together",
				]),
				RNG.pick([
					"being made to shift into new shapes and experience their every detail",
					"being someone's shapeshifting playtoy with no say about the form it will have at any given time",
					"having others transform {npc.him} for selfish reasons",
					"making out with another creature while both of them are undergoing transformation",
					{
						text = "night shifts, day shifts, evening and morning shifts that catch {npc.him} off guard, ever changing the shapes, aspects and color patterns of {npc.his} body",
						isPlural = true,
					},
					"not being able to recognize {npc.himself} in {npc.his} own reflection",
					"struggling to remember {npc.his} original appearance and innate species traits, mere minutes after the transformation",
				])
			],
			requirementsPair = [
				["pcIntroducedToTF"],
				["pcIntroducedToTF"],
			],
		},
		{
			fetish = Fetish.Tribadism,
			interestInWhat = {
				dom = RNG.pick([
					( "getting close and intimate with someone and rubbing "+ npc_hisHerOwnIts +" kitty against theirs" ),
					( "tangling with another creature and grinding "+ npc_hisHerOwnIts +" pussy against theirs" ),
				]),
				switch = RNG.pick([
					"intertwining {npc.his} thighs with someone else's and insatiably brushing against them",
					"passionately scissoring with someone as they both look flustered",
					"playfully tackling a charming critter and needily rubbing pussies together",
				]),
				sub = RNG.pick([
					"feeling the heat of another critter's pussy against {npc.hers}",
					"helplessly squirming beneath another creature as it needily rubs their kitty against {npc.hers}",
				]),
			}[pcPreferredSubbyType],
			requirements = ["pcHasVagina", "inmateHasVagina"],
		},
		{
			fetish = Fetish.UnconsciousSex,
			interestInWhat = {
				dom = RNG.pick([
					(
							(
									"slowly but needily fucking a sleeping critter that "
								+ RNG.pick(["hesitantly", "indulgently", "reluctantly"])
								+ " offered themselves the day before"
							)
						if(inmateLikesPenetratingOthers)
						else "selfishly fondling and tonguing through sensitive areas of a sleeping critter"
					),
					(
							(
									"finding asleep creatures and making "
								+ (
										"said creatures'"
									if(npc_they == "they")
									else "their"
								)
								+ " dreams about being penetrated by {npc.him} a little less fictional"
							)
						if(inmateLikesBeingPenetrated)
						else (
								"toying with sleeping creatures while "
							+ (
									"said creatures are"
								if(npc_they == "they")
								else "they're"
							)
							+ " quietly moaning out {npc.his} name"
						)
					),
				]),
				switch = RNG.pick([
					"falling asleep next to someone and needily frotting against them, even as both of them are no longer awake",
					"playing with a critter in a comfy slumber, or having the same favor being returned to {npc.him}",
				]),
				sub = RNG.pick([
					(
							"being gently fucked while {npc.theyre} sleeping comfy in {npc.his} bed"
						if(inmateLikesBeingPenetrated)
						else "being played with while {npc.theyre} relaxed and asleep"
					),
					(
							"having comfy dreams where {npc.theyre} lovingly fucked, with the dreams being only partly fictional"
						if(inmateLikesBeingPenetrated)
						else "sleeping curled up while being toyed by the same critter {npc.theyre} having wet dreams about"
					),
				]),
			}[pcPreferredSubbyType]
		},
		{
			fetishPair = [Fetish.VaginalSexGiving, Fetish.VaginalSexReceiving],
			interestInWhatPair = [
				RNG.pick([
					"creaming kitties in missionary pose while {npc.his} paws grope and fondle through their squirming partner's body",
					"making love to others from their front side, with all goods on display and easily accessible, and the facial expressions impossible to hide",
					(
							"needily thighfucking a creature, before "
						+ RNG.pickWeightedPairs([
							[
								"finding {npc.himself} unable to resist the temptation of entering their eagerly waiting pussy, and thoroughly using it too",
								( 0.0 if(inmateIsSubby) else 1.0 ),
							],
							[
								"being ordered to enter their kitty and thrust just as desperate into it",
								( 0.0 if(inmateIsDommy) else 1.0 ),
							],
						])
					),
					"sharing a deeply intimate wet kiss with a critter, while desperately thrusting into their pussy",
					"vaginally penetrating others while {npc.his} paws squeeze and fondle around {npc.his} partner's each and every curve",
				]),
				RNG.pick([
					"being pinned into a wall, kissed and pussyfucked, all at the same time",
					"having {npc.his} cunt thoroughly used and creamed on, while being needily groped",
					"having {npc.his} kitty penetrated by anyone needy enough",
					(
							"squirming beneath "
						+ (
								"a critter making love to {npc.his} pussy, nibbling at {npc.his} shoulder"
							if( (npc_they == "they") || RNG.chance(30) )
							else "someone as they make love to {npc.his} pussy and nibble on {npc.his} shoulder"
						)
					),
				])
			],
			requirementsPair = [
				["pcHasVagina"],
				["inmateHasVagina"],
			],
		},
	]

	var savedSkillsHolder:SkillsHolder = SkillsHolder.new()
	if(GM.main.DrugDenRun != null):
		savedSkillsHolder.loadData(GM.main.DrugDenRun.savedSkillsData)

	for changeData in potentialFetishChangesIncludingIneffective:
		var fetishPair:Array = []
		if( changeData.has("fetishPair") ):
			fetishPair = changeData.fetishPair
		elif( changeData.has("fetish") ):
			fetishPair = [changeData.fetish]
		else:
			print("[JunkieRehabilitation] Error: No fetish specified.")
			continue

		for fetish in fetishPair:
			var fetishIdx:int = 0 if( fetish == fetishPair[0] ) else 1

			var hasUnmetRequirements:bool = false
			var requirements:Array = (
					changeData.requirementsPair[fetishIdx]
				if( changeData.has("requirementsPair") )
				else (
						changeData.requirements
					if( changeData.has("requirements") )
					else []
				)
			)

			for requirementKey in requirements:
				if(requirementKey == "pcHasAnus"):
					if( !GM.pc.hasAnus() ):
						hasUnmetRequirements = true
						break
				elif(requirementKey == "pcHasVagina"):
					if( !GM.pc.hasVagina() ):
						hasUnmetRequirements = true
						break
				elif(requirementKey == "inmateHasAnus"):
					if( !inmateChar.hasAnus() ):
						hasUnmetRequirements = true
						break
				elif(requirementKey == "inmateHasVagina"):
					if( !inmateChar.hasVagina() ):
						hasUnmetRequirements = true
						break
				elif(requirementKey == "pcIntroducedToTF"):
					if( !GM.main.getFlag("ElizaModule.s1hap") ):
						hasUnmetRequirements = true
						break
				else:
					print( "[JunkieRehabilitation] Error: Unknown requirement \""+ requirementKey +"\"." )

			if(hasUnmetRequirements):
				continue

			var fetishPaired = fetishPair[ 1 if(fetishIdx == 0) else 0 ] if( fetishPair.size() == 2 ) else fetishPair[0]
			var pcValue:float = pcFetishHolder.getFetishValue(fetishPaired)
			var doesPlayerCharLikePairedFetishAtLeastSlightly:bool = (pcValue >= 0.125)

			if(!doesPlayerCharLikePairedFetishAtLeastSlightly):
				var isPlayerCharNeutralToFetish = ( (pcValue > -0.075) && (pcValue < 0.075) )

				if(isPlayerCharNeutralToFetish):
					pcValue = sideEffects_getPlayerCharEstimateInterestForFetish(fetishPaired, savedSkillsHolder)
					doesPlayerCharLikePairedFetishAtLeastSlightly = (pcValue >= 0.125)

				if(!doesPlayerCharLikePairedFetishAtLeastSlightly):
					continue

			var probability:float = pcValue

			var valueBefore:float = inmateFetishHolder.getFetishValue(fetish)
			var valueAfter:float = clamp( (valueBefore + valueAdd), -1.0, 1.0 )
			var valueAddClamped:float = (valueAfter - valueBefore)
			var valueAddClampedAbsolute:float = abs(valueAddClamped)
			var isIneffective:bool = ( valueAddClampedAbsolute < ( 0.7 * abs(valueAdd) ) )

			if(isIneffective):
				continue

			var changeDataPublic:Dictionary = {
				fetish = fetish,
				valueAdd = valueAdd,
				interestInWhat = ( changeData.interestInWhatPair[fetishIdx] if( changeData.has("interestInWhatPair") ) else changeData.interestInWhat ),
				valueAddClamped = valueAddClamped,
			}

			potentialFetishChanges.append([changeDataPublic, probability])

	if( ( potentialFetishChanges.size() == 0 ) || RNG.chance(1) ):
		potentialFetishChanges.append([
			{
				fetish = Fetish.Exhibitionism,
				valueAdd = valueAdd,
				valueAddClamped = valueAdd,
				interestInWhat = RNG.pick([
					"having {npc.his} naked body on display for everyone to see",
					"never having any clothes on",
				]),
			},
			FetishInterest.SlightlyLikes
		])

	return potentialFetishChanges

func sideEffects_getIncompleteSpeciesFullName(species: Array) -> String:
	if( species.size() == 0 ):
		return "Critter"

	var specie = GlobalRegistry.getSpecies( RNG.pick(species) )

	if(specie == null):
		return "Critter"

	return specie.getVisibleName()

# Rough estimation of fetishes relevant to PC, only used for fetishes marked as indifferent
func sideEffects_getPlayerCharEstimateInterestForFetish(fetish:String, savedSkillsHolder:SkillsHolder) -> float:
	var valueEstimate:float = 0.0

	var pcPersonality = null
	var pcPersonalityMeanScore:float = 0.0
	var pcIsMean:bool = false
	var pcPersonalitySubbyScore:float = 0.0
	var pcIsDommy:bool = false

	var isPersonalityDataRequired:bool = ( fetish in [Fetish.FeetplayReceiving] )

	if(isPersonalityDataRequired):
		pcPersonality = GM.pc.getPersonality()
		pcPersonalityMeanScore = pcPersonality.personalityScoreMax({ PersonalityStat.Mean: 1.0 })
		pcIsMean = (pcPersonalityMeanScore > 0.4)
		pcPersonalitySubbyScore = pcPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
		pcIsDommy = pcPersonalitySubbyScore < -0.4

	if( fetish in [Fetish.AnalSexGiving, Fetish.VaginalSexGiving] ):
		if( savedSkillsHolder.hasPerk(Perk.BreedCumProduction) || ( ( savedSkillsHolder.getSkill(Skill.Breeder) != null ) && savedSkillsHolder.getSkill(Skill.Breeder).getLevel() >= 20 ) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif( fetish in [Fetish.AnalSexReceiving, Fetish.VaginalSexReceiving] ):
		if( savedSkillsHolder.hasPerk(Perk.CumSloppySeconds) || ( ( savedSkillsHolder.getSkill(Skill.CumLover) != null ) && savedSkillsHolder.getSkill(Skill.CumLover).getLevel() >= 20 ) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.Bodywritings):
		if( savedSkillsHolder.hasPerk(Perk.BDSMTallyMarks) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.Breeding):
		if( savedSkillsHolder.hasPerk(Perk.BreedCumInflationHeat) || savedSkillsHolder.hasPerk(Perk.BreedRapidConception) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.BeingBred):
		if( savedSkillsHolder.hasPerk(Perk.FertilityBroodmother) || ( ( savedSkillsHolder.getSkill(Skill.Fertility) != null ) && savedSkillsHolder.getSkill(Skill.Fertility).getLevel() >= 20 ) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.FeetplayGiving):
		if( ( GlobalRegistry.getModule("ArticaModule") != null ) && GlobalRegistry.getModule("ArticaModule").isVerySlut() ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.FeetplayReceiving):
		if(!pcIsDommy && !pcIsMean):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.HypnosisHypnotist):
		if( savedSkillsHolder.hasPerk(Perk.HypnosisAmateurHypnotist) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.HypnosisSubject):
		if( savedSkillsHolder.hasPerk(Perk.HypnosisKeywordsDrawback) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.Lactation):
		if( savedSkillsHolder.hasPerk(Perk.MilkFasterProduction) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.OralSexReceiving):
		valueEstimate = FetishInterest.SlightlyLikes
		return valueEstimate
	elif(fetish == Fetish.OralSexGiving):
		if( savedSkillsHolder.hasPerk(Perk.CumBreath) || savedSkillsHolder.hasPerk(Perk.CumSwallower) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.Rigging):
		if( savedSkillsHolder.hasPerk(Perk.BDSMRigger) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate
	elif(fetish == Fetish.Bondage):
		if( savedSkillsHolder.hasPerk(Perk.BDSMBondageSlut) ):
			valueEstimate = FetishInterest.SlightlyLikes
			return valueEstimate

	return valueEstimate

func sideEffects_getFetishVerb(theValue:float) -> String:
	if(theValue <= -0.875):
		return "hate"
	elif(theValue <= -0.625):
		return "really dislike"
	elif(theValue <= -0.375):
		return "dislike"
	elif(theValue <= -0.125):
		return "slightly dislike"
	elif(theValue <= 0.125):
		return "feel indifferent about"
	elif(theValue <= 0.375):
		return "kinda like"
	elif(theValue <= 0.625):
		return "like"
	elif(theValue <= 0.875):
		return "really like"
	return "love"

func sideEffects_getFetishVerbS(theValue:float) -> String:
	if(theValue <= -0.875):
		return "{npc.verb('hate')}"
	elif(theValue <= -0.625):
		return "really {npc.verb('dislike')}"
	elif(theValue <= -0.375):
		return "{npc.verb('dislike')}"
	elif(theValue <= -0.125):
		return "slightly {npc.verb('dislike')}"
	elif(theValue <= 0.125):
		return "{npc.verb('feel')} indifferent about"
	elif(theValue <= 0.375):
		return "kinda {npc.verb('like')}"
	elif(theValue <= 0.625):
		return "{npc.verb('like')}"
	elif(theValue <= 0.875):
		return "really {npc.verb('like')}"
	return "{npc.verb('love')}"

func sideEffects_applyToCharacter(inmateChar:BaseCharacter) -> Array:
	var statusLines:Array = []
	var drugDenRun:DrugDen = GM.main.DrugDenRun

	if(drugDenRun == null):
		statusLines = []
		return statusLines

	var currentFloor:int = drugDenRun.getLevel()

	var sideEffectTarget:String = (
			"personality"
		if( (currentFloor <= 2) && RNG.chance(20) )
		else "fetishes"
	)

	if(sideEffectTarget == "personality"):
		var valueAddByFloor:Array = [-0.15, -0.10]
		var valueAdd:float = valueAddByFloor[currentFloor - 1] * RNG.randf_range(0.8, 1.2)

		var inmatePersonality:Personality = inmateChar.getPersonality()
		var potentialPersonalityChanges:Array = sideEffects_getPotentialPersonalityChanges(inmateChar, valueAdd)

		var randomPersonalityChange:Dictionary = RNG.pick(potentialPersonalityChanges)

		var shownDiffFloat:float = Util.roundF( (randomPersonalityChange.valueAddClamped * 100), 1 )
		if( randomPersonalityChange.has("shouldInvertShownSign") ):
			shownDiffFloat = -shownDiffFloat

		inmatePersonality.addStat(randomPersonalityChange.personalityStat, randomPersonalityChange.valueAdd)

		statusLines.append(
				"{npc.name} became [color=#E7B4BD]"
			+ (
					"a little"
				if(randomPersonalityChange.valueAdd > 0.12)
				else "slightly"
			)
			+ " "
			+ randomPersonalityChange.becameWhat
			+ "[/color]. ["
			+ (
						str(shownDiffFloat)
					if(shownDiffFloat < 0.0)
					else ( "+"+ str(shownDiffFloat) )
			)
			+ "%]"
		)
	elif(sideEffectTarget == "fetishes"):
		var valueAddByFloor:Array = [-0.15, -0.10, 0.02]
		for n in 2:
			valueAddByFloor.append( valueAddByFloor[-1] + 0.04 )
		for n in 5:
			valueAddByFloor.append( valueAddByFloor[-1] + 0.03 )
		for n in 5:
			valueAddByFloor.append( valueAddByFloor[-1] + 0.02 )
		for n in 10:
			valueAddByFloor.append( valueAddByFloor[-1] + 0.01 )

		var valueAdd_first:float = ( valueAddByFloor[currentFloor - 1] if( valueAddByFloor[currentFloor - 1] != null ) else valueAddByFloor[-1] )
		var valueAdd_second:float = ( (valueAdd_first - 0.20) if(valueAdd_first > 0.30) else 0.0 )
		valueAdd_first *= RNG.randf_range(0.8, 1.2)
		valueAdd_second *= RNG.randf_range(0.8, 1.2)

		var randomFetishChanges:Array = []
		var inmateFetishHolder:FetishHolder = inmateChar.getFetishHolder()
		var potentialFetishChanges_first:Array = sideEffects_getPotentialFetishChanges(inmateChar, valueAdd_first)
		var potentialFetishChanges_first_randomPick:Dictionary = RNG.pickWeightedPairs(potentialFetishChanges_first)
		randomFetishChanges.append(potentialFetishChanges_first_randomPick)

		if( (valueAdd_second > 0.0) && ( potentialFetishChanges_first.size() >= 2 ) ):
			var potentialFetishChanges_second:Array = sideEffects_getPotentialFetishChanges(inmateChar, valueAdd_second)
			var potentialFetishChanges_second_randomGrab = RNG.grabWeightedPairs(potentialFetishChanges_second)

			var isSecondFetishAlreadyPresent:bool = ( potentialFetishChanges_second_randomGrab.fetish == potentialFetishChanges_first_randomPick.fetish )
			if(isSecondFetishAlreadyPresent):
				potentialFetishChanges_second_randomGrab = RNG.grabWeightedPairs(potentialFetishChanges_second)

			if(potentialFetishChanges_second_randomGrab != null):
				randomFetishChanges.append(potentialFetishChanges_second_randomGrab)

		for randomFetishChange in randomFetishChanges:
			var shownDiffFloat:float = Util.roundF( (randomFetishChange.valueAddClamped * 100), 1 )

			inmateFetishHolder.addFetish(randomFetishChange.fetish, randomFetishChange.valueAdd)

			var randomFetishValueAfter:float = inmateFetishHolder.getFetishValue(randomFetishChange.fetish)

			var isRandomFetishValueAddPositive:bool = (randomFetishChange.valueAdd > 0.0)
			var isRandomFetishValueAfterPositive:bool = (randomFetishValueAfter > 0.0)

			var interestInWhat_text:String = ""
			var interestInWhat_isPlural:bool = false

			if(randomFetishChange.interestInWhat is Dictionary):
				interestInWhat_text = randomFetishChange.interestInWhat.text
				interestInWhat_isPlural = randomFetishChange.interestInWhat.isPlural
			else:
				interestInWhat_text = randomFetishChange.interestInWhat

			statusLines.append(
					"{npc.name} has "
				+ (
						(
								"[color=#C4D8C8]permanently gained "
							+ (
									RNG.pick(["a small", "slight"])
								if(randomFetishChange.valueAdd < 0.06)
								else (
										RNG.pick(["great", "immense", "significant"])
									if(randomFetishChange.valueAdd > 0.28)
									else "some"
								)
							)
							+ " interest in"
						)
					if(randomFetishChange.valueAdd > 0.0)
					else "[color=#E7B4BD]permanently lost some interest in"
				)
				+ " "
				+ interestInWhat_text
				+ "[/color] ["
				+ (
						str(shownDiffFloat)
					if(shownDiffFloat < 0.0)
					else ( "+"+ str(shownDiffFloat) )
				)
				+ "%], "
				+ (
						RNG.pickWeightedPairs([
							[
								(
										"{npc.he} now "
									+ sideEffects_getFetishVerbS(randomFetishValueAfter)
									+ " "
									+ ( "them" if(interestInWhat_isPlural) else "it" )
									+ "."
								),
								4.0
							],
							[
								(
										"from now on {npc.he} "
									+ sideEffects_getFetishVerbS(randomFetishValueAfter)
									+ " "
									+ ( "them" if(interestInWhat_isPlural) else "it" )
									+ "."
								),
								1.0
							],
							[
								(
										( "those are" if(interestInWhat_isPlural) else "that's" )
									+ " now something {npc.he} "
									+ sideEffects_getFetishVerbS(randomFetishValueAfter)
									+ "."
								),
								1.0
							],
						])
					if(
							isRandomFetishValueAddPositive
						== isRandomFetishValueAfterPositive
					)
					else (
							RNG.pick(["although", "but", "however", "though"])
						+ " {npc.he} "
						+ RNG.pick([
							(
									"still "
								+ sideEffects_getFetishVerbS(randomFetishValueAfter)
								+ " "
								+ ( "them" if(interestInWhat_isPlural) else "it" )
								+ "."
							),
							(
									"{npc.verb('continue')} to "
								+ sideEffects_getFetishVerb(randomFetishValueAfter)
								+ " "
								+ ( "them" if(interestInWhat_isPlural) else "it" )
								+ "."
							),
						])
					)
				)
			)

	return statusLines

func scenario_missingPerson_rollForShouldStart() -> bool:
	var wasScenarioTriggered:bool = false

	if(hasRecognizedPill == true):
		wasScenarioTriggered = false
		return wasScenarioTriggered

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
			var customNameOrEmpty:String = GlobalRegistry.getModule("JunkieRehabilitationModule").pickCustomName()
			if( !customNameOrEmpty.empty() ):
				missingPerson_name = customNameOrEmpty
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

func consumables_addButtons():
	var itemCount:int = 0

	var consumables:Array = [
		{
			buttonLabel = "Painkillers",
			actionDescriptionBase = "Take a single pill of painkillers to lose 80 pain.",
			simpleNameSingular = "pill",
			buttonPositionIndexes = [4],
			actionKey = "consume_painkillers",
			itemId = "painkillers",
		},
		{
			buttonLabel = "Anaphro",
			actionDescriptionBase = "Take an anaphrodisiac pill to remove any lust you may have.",
			simpleNameSingular = "pill",
			buttonPositionIndexes = [9],
			actionKey = "consume_anaphrodisiac",
			itemId = "AnaphrodisiacPill",
		},
		{
			buttonLabel = "Apple",
			actionDescriptionBase = "Eat a stolen apple to lose 30 pain and gain 30 stamina.",
			simpleNameSingular = "apple",
			buttonPositionIndexes = [3, 13],
			actionKey = "consume_apple",
			itemId = "appleitem",
		},
		{
			buttonLabel = "Cola",
			actionDescriptionBase = "Drink an energy drink to gain 100 stamina.",
			simpleNameSingular = "soda can",
			buttonPositionIndexes = [14],
			actionKey = "consume_cola",
			itemId = "EnergyDrink",
		},
	]

	var pcInventory:Inventory = GM.pc.getInventory()
	for consumable in consumables:
		itemCount = pcInventory.getAmountOf(consumable.itemId)

		var ACTION_NAME:String = (
				str(itemCount)
			+ "x "
			+ consumable.buttonLabel
		)

		var ACTION_DESC:String = (
				consumable.actionDescriptionBase
			+ "\n[i]"
			+ (
					(
							"You do not have any "
						+ consumable.simpleNameSingular
						+ "s left."
					)
				if(itemCount == 0)
				else (
						"You have "
					+ str(itemCount)
					+ " "
					+ consumable.simpleNameSingular
					+ ( "" if(itemCount == 1) else "s" )
					+ " left."
				)
			)
			+ "[/i]"
		)

		for buttonPositionIdx in consumable.buttonPositionIndexes:
			if(itemCount < 1):
				addDisabledButtonAt(buttonPositionIdx, ACTION_NAME, ACTION_DESC)
			else:
				addButtonAt(buttonPositionIdx, ACTION_NAME, ACTION_DESC, consumable.actionKey)

func consumable_consumeItemMatchingIDAndActionName(itemID, actionName) -> bool:
	var wasConsumed:bool = false
	var consumableItem = GM.pc.getInventory().getFirstOf(itemID)
	if(consumableItem == null):
		wasConsumed = false
		return wasConsumed
	var consumableItemActions = consumableItem.getPossibleActions()
	if(consumableItemActions == null):
		wasConsumed = false
		return wasConsumed
	for consumableItemAction in consumableItemActions:
		if(consumableItemAction.name == actionName):
			runScene( consumableItemAction.scene, [ consumableItem.getUniqueID() ] )
			wasConsumed = true
			return wasConsumed
	wasConsumed = false
	return wasConsumed

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

		var itemCount:int = GM.pc.getInventory().getAmountOf("JunkieRehabilitationPill")
		var ACTION_NAME_REHABILITATE:String = "Rehabilitate"
		var ACTION_DESC_REHABILITATE:String = (
				"Force them to swallow a \"JunkieBeMine\" pill, which will make them leave this place and return to the cellblock.\n[i]"
			+ (
					"You do not have any pills left."
				if(itemCount == 0)
				else ( "You have "+ str(itemCount) +" pill"+ ( "" if(itemCount == 1) else "s" )+" left." )
			)
			+ "[/i]"
		)

		if(itemCount < 1):
			addDisabledButton(ACTION_NAME_REHABILITATE, ACTION_DESC_REHABILITATE)
		else:
			addButton(ACTION_NAME_REHABILITATE, ACTION_DESC_REHABILITATE, "gave_pill")

		addButton("Leave", "Just leave. You'll likely never meet them again, but that's okay.", "left_without_giving_pill")

		# Makes the interface too busy and distracting, uncomment only if you really have to
		#consumables_addButtons()

	if(state == "gave_pill"):
		playAnimation(StageScene.SexOral, "start", {pc="pc", npc=npcID})

		saynn(
				"You produce a \"[color=#FFD8E8]Junkie[/color][color=#D0FCFC]BeMine[/color]\" pill and "
			+ (
					"were about to "
				if(hasRecognizedPill)
				else ""
			)
			+ "force {npc.him} to swallow "
			+ ( "the pill" if( getCharacter(npcID).himHer() == "it" ) else "it" )
			+ (
					", when-"
				if(hasRecognizedPill)
				else "."
			)
		)

		var eventLinesSequence:Array = []

		if(hasRecognizedPill):
			eventLinesSequence.append(
					"[say=npc]"
				+ RNG.pick([
						"Ooh I know what that is.",
						"Oh hey, I've been around long enough to recognize what you're smuggling.",
						"Ooh so you've defeated me and now you wish to take me on a date?",
						"You've only just met me and already seem so obsessed~.",
					])
				+ " "
				+ RNG.pick([
					"Kinky~..",
					"You naughty thing~.",
					"So bold of you. I find that adorable~.",
					"Can't you see I'm out of your league?~. Teehee.",
				])
				+ " "
				+ RNG.pick([
					"Truth be told I've been looking for a way out of here, so I'll take you up on that offer.",
					"No promises on that whole being yours thing, but you've bested me fair and square, so I'll accept one from you.",
					"Let me think about it for a moment. If I'm not hundred percent certain, that's not a bridge I can easily cross back.. Hmph.. Alright.",
					"You could've just asked, y'know?~ Well, you'd be hard pressed to find a critter actually willing to leave the den. I'm the odd one out. So I get it. And sure, I'll take your silly pill.",
				])
				+ "[/say]"
			)

			eventLinesSequence.append(
				RNG.pick([
					"{npc.He} {npc.verb('look')} towards you, then again towards the pill in your paws.",
					"{npc.He} {npc.verb('gaze')} off into the distance too blurred to make anything out.",
					"{npc.He} {npc.verb('stare')} quietly into the ground, then continues.",
					"{npc.He} {npc.verb('balance')} between {npc.his} left and right side for a moment, then continues.",
					"You look at {npc.him} a little guilty.",
					(
							(
									"If not for your arm restraints, you'd be petting {npc.his} "
								+ (
										"hair"
									if( getCharacter(npcID).hasHair() ) 
									else "face cheeks"
								)
								+ " right now.."
							)
						if( GM.pc.hasBoundArms() || GM.pc.hasBlockedHands() )
						else (
								"You can't resist petting through {npc.his} "
							+ (
									"hair"
								if( getCharacter(npcID).hasHair() ) 
								else "face cheeks"
							)
							+ " while {npc.theyre} talking."
						)
					),
					"Huh..",
				])
			)

			eventLinesSequence.append(
					"[say=npc]"
				+ RNG.pick([
					"Just don't make me regret trusting you.",
					"Many of my memories are of den and its folk.. alas, this place has long overstayed its welcome. Prove it to me that you can do better.",
					"If the side effect rumors are even remotely true, I'll have your body serve me as a practice toy for every kink I ever found myself interested in.",
					"That's a significant part of my life I'm leaving behind, so you'll have a loooot of making up to me on your list.",
				])
				+ "[/say]"
			)
		else:
			var possibleDialogueLines:Array = [
				"No.. What have you-",
				"F- Fucker.. What "+ RNG.pick(["are you", "do you think you're"]) +"-",
				( "I am not "+ RNG.pick(["done", "finished"]) +" with you yet.. Fuck.." ),
				"Get your hand- Fshkf..",
				( "How about you "+ RNG.pick(["shove", "stuff"]) +" this up your-" ),
				( "I will "+ RNG.pick(["fuck", "mess"]) +" you up- mffmfh.." ),
				"I will bite your fucking arm off- ffhfmm..",
			]

			if(sceneID == "DrugDenEncounterBossScene"):
				possibleDialogueLines.append_array([
					"Whore. You don't deserve even a fraction of this lab.. What are y-",
					"You think you got this all figured out? My thugs will- The fuck are you-..",
					"You're still an amateur that would waste this state-of-the-art equipment to make a fucking painkil- Get your dirty hands off me! Mfhhsfh-"
				])
			else:
				possibleDialogueLines.append_array([
					( "So "+ RNG.pick(["kind", "nice"]) +" of you to share~" ),
					"Oooh new product! Gimme-ahff~",
					"Mm, you like watching me swallow? Freak~.. mmhf-",
					"No need to be so.. hhf.. forcefhul.. Let me savor it..",
					"W- Would you have some milk to help me swallow? P- Please... mffhfm..",
					(
							"Fuck off-.. "
						+ RNG.pick(["H- Hold on", "W- Wait"])
						+ ".. "
						+ RNG.pick(["I want to try it", "Let me try it"])
						+ ".."
					),
					(
							RNG.pick([
								"You really expect me to just sample random drugs now?",
								"Do I look like a fucking test subject?",
								"You think defeating me once makes you my dealer or something?",
								"You're not my fucking dealer.",
								"I don't accept drugs from just anyone.",
							])
						+ " "
						+ RNG.pick([
							"Get lost- hhfggh",
							"Move the fuck away- nfhhfgg",
							"Hey! Nnnmhh..",
						])
					),
					(
							"Ooh new shiny thing, hell yeah! "
						+ RNG.pick([
							"Come on",
							"Don't just stand there",
						])
						+ ", give give give give.."
					),
					(
							"This one definitely "
						+ RNG.pick(["catches", "has"])
						+ " my attention.. "
						+ RNG.pick([
							"Care to share?..",
							"Give me a taste..",
						])
					),
				])

			eventLinesSequence.append( "[say=npc]"+ RNG.pick(possibleDialogueLines) +"[/say]" )

		for eventLine in eventLinesSequence:
			saynn(eventLine)

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
			if(hasRecognizedPill):
				var possibleEventLines_action:Array = [
					"{npc.name} consumes the pill out of your paws. {npc.He} then {npc.verb('stare')} at you for a little longer, and eventually {npc.verb('doze')} off from the meds.",
				]

				saynn( RNG.pick(possibleEventLines_action) )

				if( RNG.chance(20) ):
					var possibleEventLines_reaction:Array = [
						"You remain quiet and only swallow uncomfortably.",
					]

					saynn( RNG.pick(possibleEventLines_reaction) )
				else:
					var possibleDialogueLines_reaction:Array = [
						"I'll make it worth.",
						"I-.. I will try my best..",
						"Sigh. Not going to be simple..",
						"Thank you for believing in me.",
						"Mmh.. Won't be easy..",
					]

					saynn( "[say=pc]"+ RNG.pick(possibleDialogueLines_reaction) +"[/say]" )
			else:
				var possibleEventLines_action:Array = [
					"Weakened after the fight, {npc.name} falls onto {npc.his} spine, slipping into slumber.",
					"There is no stamina left in {npc.name} to resist, and {npc.he} {npc.verb('collapse')} on {npc.his} side, beside you.",
					"No more words leave {npc.nameS} mouth. For a brief moment, {npc.he} {npc.verb('stare')} at you with an alert expression, then.. {npc.verb('doze')} off.",
					"Lacking strength to defy you, {npc.name} flops on {npc.his} back, closely following your movements for a few seconds, before inevitably falling asleep.",
				]

				saynn( RNG.pick(possibleEventLines_action) )

				var pcPersonality:Personality = GM.pc.getPersonality()
				var pcFetishHolder:FetishHolder = GM.pc.getFetishHolder()

				var pcPersonalitySubbyScore:float = pcPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
				var pcIsSubby:bool = pcPersonalitySubbyScore > 0.4
				var pcIsDommy:bool = pcPersonalitySubbyScore < -0.4

				var pcInterestInRiggingOthers:float = pcFetishHolder.scoreFetishMax({ Fetish.Rigging: 1.0 })
				var pcLikesRiggingOthers:bool = pcInterestInRiggingOthers >= 0.5

				var junkieSpecies:Array = getCharacter(npcID).getSpecies()

				var possibleDialogueLines_reaction:Array = [
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
					possibleDialogueLines_reaction.append_array([
						"You'd make an excellent plaything, dear. Don't let anyone snatch you before I get a good look holding you by the collar~",
						"Next time I see you roam the cellblock in full consciousness, I'm pinning you against the nearest wall and making you my own~",
					])
				elif(pcIsSubby == true):
					possibleDialogueLines_reaction.append_array([
						"I'm already envisioning all the things I'd let you do to me..",
						"Guh.. Can't wait for you to play with me..",
						"Why does everyone here have to be so hot.. Fuck..",
					])

				if(pcLikesRiggingOthers == true):
					possibleDialogueLines_reaction.append_array([
						"I'm already so tempted to bind you in ropes, hh.. If it didn't complicate your traversal at a time when I need you to safely leave the den, I definitely would~",
					])

				for junkieSpeciesId in junkieSpecies:
					if( junkieSpeciesId.ends_with("eon") || junkieSpeciesId.ends_with("vee") ):
						possibleDialogueLines_reaction.append_array([
							"I don't care what the data on your collar says, you're a shiny to me~",
						])

						break

				saynn( "[say=pc]"+ RNG.pick(possibleDialogueLines_reaction) +"[/say]" )

		addMessage("[color=#D3D3E5]{npc.name} can now be found around the cellblock.[/color]")

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
		else:
			if( sideEffects_statusLines.size() >= 1 ):
				addMessage(
						"\n[color=#9E9EC2]The pill seems to have caused some side effects:\n[/color][color=#D3D3E5]"
					+ Util.join(sideEffects_statusLines, "\n[color=#9E9EC2]–[/color]\n")
					+ "[/color]"
				)

		addButton("Leave", "Let them recover at their own pace.", "after_swallowed_pill")

		# Makes the interface too busy and distracting, uncomment only if you really have to
		#consumables_addButtons()

	if(state == "consumed_item_after_swallowed_pill"):
		clearCharacter()
		playAnimation(StageScene.Solo, "stand")
		saynn("You consider whether to use any other items.")
		addButton("Continue", "Enough using items.", "after_swallowed_pill")
		consumables_addButtons()

	if(state == "consumed_item_after_encounter_survived_sex"):
		clearCharacter()
		playAnimation(StageScene.Solo, "stand")
		saynn("You consider whether to use any other items.")
		addButton("Continue", "Enough using items.", "endthescene")
		consumables_addButtons()
		
	if(state == "lost_encounter"):
		playAnimation(StageScene.Duo, "defeat", {npc=npcID})
		
		saynn("You lost! Looks like the junkie is eager to fuck you.")
		
		addButton("Continue", "See what happens next", "start_defeated_sex")
	
	if(state == "encounter_survived_sex"):
		removeCharacter(npcID)
		saynn("You managed to endure the onslaught! Time to run!")
		
		addButton("Continue", "See what happens next", "endthescene")

		consumables_addButtons()
		
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
		var inmateChar:DynamicCharacter = rehabilitateJunkie()

		if( scenario_missingPerson_isActive() == true ):
			scenario_missingPerson_checkForWasCompleted()

		if(scenario_missingPerson_foundForSeekerName == ""):
			var inmatePersonality:Personality = inmateChar.getPersonality()
			var inmatePersonalityPerceptiveRatio:float = ( inmatePersonality.personalityScoreMax({ PersonalityStat.Naive: -1.0 }) + 1.0 ) / 2.0

			hasRecognizedPill = (
					(sceneID != "DrugDenEncounterBossScene")
				&& RNG.chance(5.0 * inmatePersonalityPerceptiveRatio)
			)

		setState("gave_pill")
		return true
	if(_action == "swallowed_pill"):
		if( scenario_missingPerson_rollForShouldStart() == true ):
			scenario_missingPerson_generateDetails()
			scenario_missingPerson_started = true
		else:
			if(scenario_missingPerson_foundForSeekerName == ""):
				sideEffects_statusLines = sideEffects_applyToCharacter( getCharacter(npcID) )

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

	if(_action == "consume_painkillers"):
		consumable_consumeItemMatchingIDAndActionName("painkillers", "Consume")
	if(_action == "consume_anaphrodisiac"):
		consumable_consumeItemMatchingIDAndActionName("AnaphrodisiacPill", "Consume")
	if(_action == "consume_apple"):
		consumable_consumeItemMatchingIDAndActionName("appleitem", "Eat one!")
	if(_action == "consume_cola"):
		consumable_consumeItemMatchingIDAndActionName("EnergyDrink", "Consume")
	if( _action.begins_with("consume_") ):
		if( getState() == "swallowed_pill" ):
			setState("consumed_item_after_swallowed_pill")
		if( getState() == "encounter_survived_sex" ):
			setState("consumed_item_after_encounter_survived_sex")
		return true

	return false

func saveData():
	var data = .saveData()
	
	data["npcID"] = npcID
	data["hasRecognizedPill"] = hasRecognizedPill
	data["se_sl"] = sideEffects_statusLines
	data["scn_mp_started"] = scenario_missingPerson_started
	data["scn_mp_foundForSeekerName"] = scenario_missingPerson_foundForSeekerName
	
	return data
	
func loadData(data):
	.loadData(data)
	
	npcID = SAVE.loadVar(data, "npcID", "")
	hasRecognizedPill = SAVE.loadVar(data, "hasRecognizedPill", false)
	sideEffects_statusLines = SAVE.loadVar(data, "se_sl", [])
	scenario_missingPerson_started = SAVE.loadVar(data, "scn_mp_started", false)
	scenario_missingPerson_foundForSeekerName = SAVE.loadVar(data, "scn_mp_foundForSeekerName", "")

func getSceneCreator():
	if(state in ["wonFight", "gave_pill", "swallowed_pill", "consumed_item_after_swallowed_pill", "consumables_quick_access"]):
		return "keerifox"
	else:
		return "Rahi"
