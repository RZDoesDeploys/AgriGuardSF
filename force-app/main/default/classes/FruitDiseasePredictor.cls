public class FruitDiseasePredictor implements Queueable, Database.AllowsCallouts {

    private FruitDisease__c record;

    public FruitDiseasePredictor(FruitDisease__c record) {
        this.record = record;
    }

    public void execute(QueueableContext context) {
        if (String.isBlank(record.Id) || String.isBlank(record.Image__c)) {
            System.debug('Missing record ID or input');
            return;
        }

        // Extract refid from Image__c (expected to be a content URL with refid=...)
        Pattern pattern = Pattern.compile('refid=([a-zA-Z0-9]+)');
        Matcher matcher = pattern.matcher(record.Image__c);

        String refid = '';
        if (matcher.find()) {
            refid = matcher.group(1);
        }

        String base64Image = getBase64Image(record.Id, refid);
        if (String.isBlank(base64Image)) {
            System.debug('Image fetch failed.');
            return;
        }

        Map<String, Object> payload = new Map<String, Object>{
            'image_base64' => base64Image
        };

        String result = sendImageForPrediction(JSON.serialize(payload));
        if (result != null) {
            try {
                // Parse result and update the record
                record.JSONResult__c = result;
                update record;
            } catch (Exception e) {
                System.debug('Failed to update record: ' + e.getMessage());
            }
        }
    }

    private String getBase64Image(String recId, String refId) {
        String endpoint = '/services/data/v63.0/sobjects/FruitDisease__c/' + recId +
                          '/richTextImageFields/Image__c/' + refId;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainURL().toExternalForm() + endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return EncodingUtil.base64Encode(res.getBodyAsBlob());
        } else {
            System.debug('Image fetch failed: ' + res.getStatus() + ' - ' + res.getBody());
            return null;
        }
    }

    private String sendImageForPrediction(String payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AgriGuardAPI/predict_base64');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Prediction Success: ' + res.getBody());
            return res.getBody();
        } else {
            System.debug('Prediction failed: ' + res.getStatus() + ' - ' + res.getBody());
            return null;
        }
    }
}