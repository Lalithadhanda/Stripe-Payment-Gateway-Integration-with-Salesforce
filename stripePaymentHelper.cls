public with sharing class stripePaymentHelper {
    public static String baseURL = 'https://api.stripe.com';
    public static Map<String, Map<String, Object>> productDataMap = new Map<String, Map<String, Object>>();
    public static String secretKey;
    public static String publisherKey;

    static{
        // UPDATED: Match your Custom Metadata Type name and field names from screenshot
        Stripe_Credentials__mdt credentials = Stripe_Credentials__mdt.getInstance('Stripe_Credential');
        secretKey = credentials.Secret_Key__c;        // From your Custom Fields
        publisherKey = credentials.Publisher_Key__c;  // From your Custom Fields
    }

    // FIXED: cacheable=true is correct here (no DML/callouts)
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(String parentId){
        return [ SELECT ID, OpportunityId, Name, Product2Id, Product2.Name, CurrencyIsoCodeText__c, ProductCode, TotalPrice, Quantity 
                FROM OpportunityLineItem 
                WHERE OpportunityId =: parentId ];
    }

    // FIXED: Removed cacheable=true (this method makes callouts and sends emails)
    @AuraEnabled
    public static String sendPaymentRequest(String productsJson){
        // Clear the map at the start to avoid stale data
        productDataMap.clear();
        
        List<OpportunityLineItem> productList = (List<OpportunityLineItem>)JSON.deserialize(productsJson, List<OpportunityLineItem>.class);
        String opptyId = productList[0].OpportunityId;
        
        for(OpportunityLineItem item: productList){
            Map<String, Object> productData = new Map<String, Object>{ 'Id' => item.Id, 'Quantity' => item.Quantity };
            String jsonStr = createPrice(item);
            if(jsonStr != null){
                 Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonStr);
                 String priceId = (String)responseMap.get('id');
                 if(priceId != null){
                    productDataMap.put(item.id, new Map<String, Object>{ 'responseId' => priceId, 'productData' => productData}); 
                 }else{
                    throw new AuraHandledException('Something Went Wrong: Price Not generated');
                 } 
            }
        }
        
        if(!productDataMap.isEmpty()){
            String paymentLinkresponse = createPayementLink();
            if(paymentLinkresponse != null){
                 Map<String, Object> responseObjMap = (Map<String,Object>) JSON.deserializeUntyped(paymentLinkresponse);
                 String paymentURL = String.valueOf(responseObjMap.get('url'));
                 if(paymentURL != null){
                    String response = sendEmailToCustomerForPayment(paymentURL, opptyId);
                    if(response.contains('Error')){
                        throw new AuraHandledException('Something Went Wrong: Email not sent to Customer');
                    }
                 }else{
                    throw new AuraHandledException('Something Went Wrong: Payment link Not generated');
                 }         
            }
        }
        return 'Success';
    } 
    
    // Email method - no annotation needed (private helper)
    public static String sendEmailToCustomerForPayment(String paymentURL, String opportunityId){
        Opportunity opportunity = [SELECT Id, Name, Account.Name, OwnerId, Owner.Email 
                                   FROM Opportunity 
                                   WHERE Id =: opportunityId ];
        if (opportunity == null) {
            return 'Error: Opportunity with Id "' + opportunityId + '" not found.';
        }
        
        // Create the email message 
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(opportunity.OwnerId);
        email.setSaveAsActivity(false);
        email.setSubject('Payment Request for: ' + opportunity.Name);
        String customerName = opportunity.Account.Name;
        email.setPlainTextBody('Dear ' + customerName + ',' + 
                          '\n\nClick on this link ' + paymentURL + ' to make a payment for your recent purchase of ' + opportunity.Name + '.');
        
        // Send the email
        try{
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            return 'Payment link email sent successfully.';
        }catch(Exception e){
            return 'Error Sending Email: ' + e.getMessage();
        }
    }

    // FIXED: Removed cacheable=true (this method makes HTTP callouts)
    @AuraEnabled
    public static String createPrice(OpportunityLineItem product){
        String apiURL = baseURL + '/v1/prices';
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http httpRequest = new Http();
        
        // FIXED: Convert TotalPrice to cents (Stripe uses smallest currency unit)
        Decimal priceInCents = product.TotalPrice * 100;
        
        String requestBody = 'unit_amount=' + EncodingUtil.urlEncode(String.valueOf(priceInCents.intValue()), 'UTF-8') +
                              '&currency=' + EncodingUtil.urlEncode(String.valueOf(product.CurrencyIsoCodeText__c).toLowerCase(), 'UTF-8') +
                              '&product_data[name]=' + EncodingUtil.urlEncode(product.Product2.Name, 'UTF-8');        	
        
        System.debug('createPrice request body: ' + requestBody);
        request.setEndpoint(apiURL);
        request.setMethod('POST');
        request.setBody(requestBody);
        
        // FIXED: Stripe uses Bearer token authentication with Secret Key only
        request.setHeader('Authorization', 'Bearer ' + secretKey);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        response = httpRequest.send(request);
        
        System.debug('createPrice response status: ' + response.getStatusCode());
        System.debug('createPrice response body: ' + response.getBody());
        
        if(response.getStatusCode() == 200) { 
            return response.getBody();
        } else {
            System.debug('Error creating price: ' + response.getBody());
            throw new AuraHandledException('Error Processing Payment From Apex: ' + response.getBody());
        }
    }
    
    // FIXED: Removed cacheable=true (this method makes HTTP callouts)
    @AuraEnabled
    public static String createPayementLink(){
        Integer lineItemIndex = 0;
        String requestBody = '';
        
        for (String productId : productDataMap.keySet()) {
            Map<String, Object> productInfo = productDataMap.get(productId);
            String responseId = (String)productInfo.get('responseId');
            Map<String, Object> productData = (Map<String, Object>)productInfo.get('productData');
            Integer quantity = Math.round((Double)productData.get('Quantity'));
            
            // Construct the line item string manually
            String lineItem = 'line_items[' + lineItemIndex + '][price]=' + EncodingUtil.urlEncode(responseId, 'UTF-8') + 
                     '&line_items[' + lineItemIndex + '][quantity]=' + quantity;
            
            if(lineItemIndex > 0) {
                requestBody += '&' + lineItem;
            } else {
                requestBody += lineItem;
            }
            lineItemIndex++;
        }
        
        String apiURL = baseURL + '/v1/payment_links';
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http httpRequest = new Http();  	
        
        System.debug('createPaymentLink request body: ' + requestBody);
        request.setEndpoint(apiURL);
        request.setMethod('POST');
        request.setBody(requestBody);
        
        // FIXED: Stripe uses Bearer token authentication with Secret Key only
        request.setHeader('Authorization', 'Bearer ' + secretKey);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        response = httpRequest.send(request);
        
        System.debug('createPaymentLink response status: ' + response.getStatusCode());
        System.debug('createPaymentLink response body: ' + response.getBody());
        
        if(response.getStatusCode() == 200) { 
            return response.getBody();
        } else {
            System.debug('Error creating payment link: ' + response.getBody());
            throw new AuraHandledException('Error Processing Payment From Apex: ' + response.getBody());
        }
    }
}
