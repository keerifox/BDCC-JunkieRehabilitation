**Notice:** This repository contains adult themes including sexual content, and is meant to be viewed by adults only.

JunkieRehabilitation is a mod for [BDCC](https://github.com/Alexofp/BDCC) adding a new drug which allows to rehabilitate defeated Drug Den junkies into cellblock inmates, in case you wish to meet them again.

The pill can sometimes be found as loot. Alternatively, you can purchase it for 100 credits from the Med Lobby's vendomat.

### Compatibility
`/Modules/DrugDenModule/DrugDen/DrugDenEncounterTemplateScene.gd` is overridden to allow all of this to happen.

`DrugDenEncounterBossScene.gd`, `DrugDenEncounterFirstScene.gd`, `DrugDenEncounterInstantFightScene.gd`, `DrugDenEventWhoreScene.gd` and `DrugDenEventWhoreSubScene.gd` are overridden to modify path to the class they inherit. No other lines were changed besides line 44 in the boss scene.

### License
MIT License