extends InmateGenerator
class_name RehabilitatedJunkieGenerator

func process(character:DynamicCharacter, _args = {}):
	.pickCharacterType(character, _args) # change type from Generic to Inmate
	.pickName(character, _args) # replace "Junkie" with a random name
	.pickLevel(character, _args) # replace drug den level
	.pickStats(character, _args) # replace drug den lust/pain/stamina

	var fetishHolder:FetishHolder = character.getFetishHolder()
	fetishHolder.addFetish(Fetish.DrugUse, RNG.randf_range(-1.5, -1.0))

	character.npcLootOverride = null # remove drug den loot override
	character.npcSmallDescription = .pickSmallDescription(character, _args) # replace "One of the junkies"

	character.removeEffect("DrugDenBoss1")
	character.removeEffect("DrugDenBoss2")
	character.removeEffect("DrugDenBoss3")
	character.removeEffect("DrugDenBoss4")
	character.removeEffect("DrugDenBoss5")

	.resetStats(character, _args) # set stamina to max

	character.updateNonBattleEffects()
	return character
