public with sharing class BillAPI {

    public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }

    
    public static void getBills() {
        // Step 1: Create an HttpRequest object and set the endpoint and method.
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://my-json-server.typicode.com/walters954/clicked-intro-development-server/bills');
        req.setMethod('GET');
        
        // Step 2: Set up an Http object and an HTTPResponse object, then get the response body.
        Http http = new Http();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();
        
        // Step 3: Deserialize the JSON response into a list of BillWrapper objects.
        List<BillWrapper> bwList = (List<BillWrapper>)JSON.deserialize(responseBody, List<BillWrapper>.class);
        
        // Step 4: Create a list to hold the bills that will be inserted into Salesforce.
        List<Bill__c> newBills = new List<Bill__c>();
        
        // Step 5: Query for active accounts (Active__c = 'Yes')
        List<Account> activeAccounts = [SELECT Id, Name FROM Account WHERE Active__c = 'Yes'];
        
        // Step 6: Create a map to hold active account names and their IDs.
        Map<String, Id> accountMap = new Map<String, Id>();
        
        // Step 7: Iterate over the list of active accounts and add their name and ID to the map.
        for (Account acc : activeAccounts) {
            accountMap.put(acc.Name, acc.Id);
        }
        
        // Step 8: Iterate over the list of BillWrapper objects and create a new Bill__c record for each.
        for (BillWrapper bill : bills) {
            if (accountMap.containsKey(bill.accountName)) {
                Bill__c newBill = new Bill__c();
                newBill.Account__c = accountMap.get(bill.accountName);
                newBill.Bill_Id__c = bill.billId;
                newBill.Balance__c = Decimal.valueOf(bill.balance);
                newBills.add(newBill);
            }
        }
        
        // Step 9: Insert the new bills list.
        if (!newBills.isEmpty()) {
            insert newBills;
        }
    }
}