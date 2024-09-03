public with sharing class BillAPI {
    /**For debugging and shortcuts - https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/apex-writing.html
https://trailhead.salesforce.com/content/learn/projects/find-and-fix-bugs-with-apex-replay-debugger/apex-replay-debugger-debug-your-code*/

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
        System.debug(req);
    
        //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_http.htm
        // Step 2: Set up an Http object and an HTTPResponse object, then get the response body.
        Http http = new Http();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();
        System.debug(responseBody);
        System.debug(http);
        
        // Step 3: Deserialize the JSON response into a list of BillWrapper objects.
        //https://salesforce.stackexchange.com/questions/88811/deserialize-json-string-to-list-of-wrapper
        List<BillWrapper> bwList = new LIST<BillWrapper>();
        bwList = (LIST<BillWrapper>) JSON.deserialize(responseBody, List<BillWrapper>.class);
        
        // Step 4: Create a list to hold the bills that will be inserted into Salesforce.
        //https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_list.htm
        List<Bill__c> newBills = new List<Bill__c>();
        System.debug(newBills);
        
        // Step 5: Query for active accounts (Active__c = 'Yes')
        //https://salesforce.stackexchange.com/questions/296317/soql-to-find-out-all-active-users-that-comes-under-the-profile-xyz
        List<Account> activeAccounts = [SELECT Id, Name FROM Account WHERE Active__c = 'Yes'];
        
        // Step 6: Create a map to hold active account names and their IDs.
        //https://trailhead.salesforce.com/trailblazer-community/feed/0D54V00007T4St8SAF
        //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_collections_maps.htm
        Map<String, Id> accountMap = new Map<String, Id>();
        
        // Step 7: Iterate over the list of active accounts and add their name and ID to the map.
        for (Account acc : activeAccounts) {
            accountMap.put(acc.Name, acc.Id);
        }
        
        // Step 8: Iterate over the list of BillWrapper objects and create a new Bill__c record for each.
        for (BillWrapper bill : bwList) {
            // Check if the accountName exists in the accountMap
            if (accountMap.containsKey(bill.accountName)) {
                Bill__c newBill = new Bill__c();
                System.debug(newBill);
                newBill.account__c = accountMap.get(bill.accountName);
                //newBill.Id = bill.billId;
                newBill.balance__c = Decimal.valueOf(bill.balance);
                newBill.invoice_number__c = bill.billId;
                //newBill.add(newBill);
            } else {
                System.debug('No matching account found for BillWrapper with Account Name: ' + bill.accountName);
            }
        }
        //ChatGPT answer from line 52 thru 63. Not sure if this is correct
        
        // Step 9: Insert the new bills list.
        if (!newBills.isEmpty()) {
            insert newBills;
        }
    }
}