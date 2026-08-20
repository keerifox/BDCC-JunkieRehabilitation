extends EventBase

func _init():
	id = "JunkieRehabilitationConsumablesQuickAccessEvent"

func registerTriggers(es):
	es.addTrigger(self, Trigger.EnteringRoom)

func run(_triggerID, _args):
	if(GM.main.DrugDenRun == null):
		return

	var pcLocation = GM.pc.getLocation()
	if( pcLocation == GM.main.DrugDenRun.getNextLevelRoom() ):
		return

	var drugDenEvent = GM.main.DrugDenRun.getEventInRoom(pcLocation)
	if(drugDenEvent != null):
		return

	var pcInventory:Inventory = GM.pc.getInventory()
	var pcPain:float = GM.pc.getPain()
	var pcPainLevel:float = GM.pc.getPainLevel()
	var pcLustLevel:float = GM.pc.getLustLevel()
	var pcStamina:float = GM.pc.getStamina()
	var pcStaminaMax:float = GM.pc.getMaxStamina()
	var pcStaminaMissing:float = (pcStaminaMax - pcStamina)
	var pcStaminaLevel:float = GM.pc.getStaminaLevel()

	var haveAnyItemsWorthConsidering:bool = (
			(
					( pcInventory.getAmountOf("painkillers") >= 1 )
				&& (
						(pcPainLevel > 0.5)
					|| (pcPain >= 70)
				)
			)
		|| (
				( pcInventory.getAmountOf("AnaphrodisiacPill") >= 1 )
			&& (pcLustLevel > 0.5)
		)
		|| (
				( pcInventory.getAmountOf("appleitem") >= 1 )
			&& (
					(pcPainLevel > 0.5)
				|| (pcStaminaLevel < 0.5)
				|| (
						(pcPain >= 25)
					&& (pcStaminaMissing >= 25)
				)
			)
		)
		|| (
				( pcInventory.getAmountOf("EnergyDrink") >= 1 )
			&& (
					(pcStaminaLevel < 0.5)
				|| (pcStaminaMissing >= 85)
			)
		)
	)

	if(!haveAnyItemsWorthConsidering):
		return

	var isCombatEncounterNearby:bool = false
	for theDir in GameWorld.getAllDirections():
		if( !GM.world.canGoID(pcLocation, theDir) ):
			continue
		var adjacentLocation = GM.world.applyDirectionID(pcLocation, theDir)
		if(adjacentLocation == null):
			continue
		var adjacentCellDrugDenEncounter = GM.main.DrugDenRun.hasEncounterInRoom(adjacentLocation)
		if(adjacentCellDrugDenEncounter == null):
			continue
		var encounterType:int = GM.main.DrugDenRun.getEncounterType(adjacentLocation)
		if( encounterType in [DrugDen.ENCOUNTER_NORMAL, DrugDen.ENCOUNTER_BOSS] ):
			isCombatEncounterNearby = true
			break

	if(!isCombatEncounterNearby):
		return

	var ACTION_NAME_CONSUMABLES:String = "Consumables"
	var ACTION_DESC_CONSUMABLES:String = "Quick access consumables before a potential encounter."

	var unusedButtonIdx = 4
	while( GM.ui.options.has(unusedButtonIdx) ):
		if(unusedButtonIdx < 5):
			unusedButtonIdx -= 1

			if(unusedButtonIdx == -1):
				unusedButtonIdx = 5
		else:
			unusedButtonIdx += 1

	GM.ui.addButtonAt(unusedButtonIdx, ACTION_NAME_CONSUMABLES, ACTION_DESC_CONSUMABLES, "EVENTSYSTEM_BUTTON", [self, "view_consumables", []])
	
func react(_triggerID, _args):
	if(GM.main.DrugDenRun == null):
		return false

	if( GM.main.DrugDenRun.hasEncounterInRoom( GM.pc.getLocation() ) ):
		return false

	return false
	
func getPriority():
	return 0

func onButton(_method, _args):
	if(_method == "view_consumables"):
		runScene("JunkieRehabilitationConsumablesQuickAccessScene")
