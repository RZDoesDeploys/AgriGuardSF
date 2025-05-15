@isTest
private class FruitDiseasesTriggerHandlerTest {

    // Mock class for simulating callout responses
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/predict_base64')) {
                res.setStatusCode(200);
                res.setBody('{"prediction": "Apple Scab"}');
            } else {
                res.setStatusCode(200);
                res.setBody('fake image');
            }
            return res;
        }
    }

    @isTest
    static void testBeforeInsertWithPrediction() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test record with Image__c and RunPrediction__c = true
        FruitDisease__c fd = new FruitDisease__c(
            Image__c = 'https://example.com/image.png?refid=abc123',
            RunPrediction__c = true
        );

        Test.startTest();
        insert fd;  // Triggers prediction logic and enqueues job
        Test.stopTest();  // Executes queueable job

        // Reload the record to verify it was updated
        FruitDisease__c updated = [SELECT Id, JSONResult__c, RunPrediction__c FROM FruitDisease__c WHERE Id = :fd.Id LIMIT 1];
        System.assertEquals(false, updated.RunPrediction__c, 'RunPrediction__c should be reset to false');
    }

    @isTest
    static void testBeforeInsertWithoutPrediction() {
        FruitDisease__c fd = new FruitDisease__c(
            Image__c = null,
            RunPrediction__c = false
        );

        Test.startTest();
        insert fd;
        Test.stopTest();

        FruitDisease__c inserted = [SELECT Id, JSONResult__c FROM FruitDisease__c WHERE Id = :fd.Id LIMIT 1];
        System.assertEquals(null, inserted.JSONResult__c, 'No prediction should run if RunPrediction is false or Image is null');
    }

    @isTest
    static void testBeforeUpdateWithPrediction() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Initial insert
        FruitDisease__c fd = new FruitDisease__c(
            Image__c = 'https://example.com/image.png?refid=abc123',
            RunPrediction__c = false
        );
        insert fd;

        // Update to trigger prediction
        fd.RunPrediction__c = true;

        Test.startTest();
        update fd;
        Test.stopTest();

        FruitDisease__c updated = [SELECT Id, JSONResult__c, RunPrediction__c FROM FruitDisease__c WHERE Id = :fd.Id LIMIT 1];
        System.assertNotEquals(null, updated.JSONResult__c, 'Prediction result should be set on update');
        System.assertEquals(false, updated.RunPrediction__c, 'RunPrediction__c should be reset to false after update');
    }
}