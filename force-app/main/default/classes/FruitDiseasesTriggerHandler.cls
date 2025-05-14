public with sharing class FruitDiseasesTriggerHandler extends TriggerHandler {
	
    private List<FruitDisease__c> newFDList;
    private List<FruitDisease__c> oldFDList;    
    private Map<Id, FruitDisease__c> newFDMap;
    private Map<Id, FruitDisease__c> oldFDMap;
    
    public FruitDiseasesTriggerHandler() {          
        this.newFDList = (List<FruitDisease__c>) Trigger.New;
        this.oldFDList = (List<FruitDisease__c>) Trigger.Old;
        this.newFDMap = (Map<Id, FruitDisease__c>) Trigger.NewMap;
        this.oldFDMap = (Map<Id, FruitDisease__c>) Trigger.OldMap;
    } 
    
    public override void beforeInsert() { 
        runPredictions();
    }
    
    public override void beforeUpdate() { 
        runPredictions();
    }
    
    public void runPredictions(){       
        for(FruitDisease__c rec: newFDList){
            if(rec.RunPrediction__c == TRUE && rec.Image__c != NULL) {
                rec.RunPrediction__c = FALSE;    
                System.enqueueJob(new FruitDiseasePredictor(rec));
            }
        }
    }
}