public with sharing class BillAPI {
    public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }

    // Updated: Removed the insert DML statement and return the Bill__c records directly.
    @AuraEnabled(cacheable=true)
    public static List<Bill__c> getBills() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://my-json-server.typicode.com/walters954/clicked-intro-development-server/bills');
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            try {
                // Deserialize the HTTP response to BillWrapper objects
                List<BillWrapper> bills = (List<BillWrapper>) JSON.deserialize(res.getBody(), List<BillWrapper>.class);
                // Convert the BillWrapper objects to Bill__c records
                List<Bill__c> billRecords = convertToBillRecords(bills);
                // Return the Bill__c records to the Lightning Web Component
                return billRecords;
            } catch (Exception e) {
                throw new AuraHandledException('An error occurred: ' + e.getMessage());
            }
        } else {
            throw new AuraHandledException('Failed with status code: ' + res.getStatusCode());
        }
    }

    private static List<Bill__c> convertToBillRecords(List<BillWrapper> billWrapperList) {
        List<Bill__c> billRecords = new List<Bill__c>();
        Set<String> accountNames = new Set<String>();
        
        for (BillWrapper bw : billWrapperList) {
            accountNames.add(bw.accountName);
        }

        // Retrieve the Account IDs associated with the Account Names
        Map<String, Id> accountNameToIdMap = new Map<String, Id>();
        for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN :accountNames]) {
            accountNameToIdMap.put(acc.Name, acc.Id);
        }

        // Convert BillWrapper to Bill__c records
        for (BillWrapper bw : billWrapperList) {
            Bill__c newBill = new Bill__c();
            newBill.Invoice_Number__c = bw.billId;
            Id accountId = accountNameToIdMap.get(bw.accountName);
            if (accountId != null) {
                newBill.Account__c = accountId;
            } else {
                System.debug('Account not found for name: ' + bw.accountName);
            }
            String balanceWithoutDollarSign = bw.balance.replace('$', '');
            newBill.Balance__c = Decimal.valueOf(balanceWithoutDollarSign);
            billRecords.add(newBill);
        }
        
        return billRecords;
    }
}
