trigger FruitDiseaseTrigger on FruitDisease__c (before insert, after insert, before update, after update) {
	new FruitDiseasesTriggerHandler().run();
}