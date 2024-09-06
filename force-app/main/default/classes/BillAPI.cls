public with sharing class BillAPI {

    public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }

    public static void getBills() {
     
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://my-json-server.typicode.com/walters954/clicked-intro-development-server/bills');
        req.setMethod('GET');


Http http = new Http();
HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200) {
            try {
                List<BillWrapper> bills = (List<BillWrapper>) JSON.deserialize(res.getBody(), List<BillWrapper>.class);
                List<Bill__c> billRecords = convertToBillRecords(bills);
                insert billRecords;
            } catch (Exception e) {
                System.debug('An error occurred: ' + e.getMessage());
                System.debug('Failed with status code: ' + res.getStatusCode());
            }
        }
    }

    private static List<Bill__c> convertToBillRecords(List<BillWrapper> billWrapperList) {
        List<Bill__c> billRecords = new List<Bill__c>();
        Set<String> accountNames = new Set<String>();
        
        for (BillWrapper bw : billWrapperList) {
            accountNames.add(bw.accountName);
        }

        Map<String, Id> accountNameToIdMap = new Map<String, Id>();
        for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN :accountNames]) {
            //System.debug('acc----------->' + acc);
            //System.debug('line41!!!!!!!!!!!!!' + accountNameToIdMap);
            accountNameToIdMap.put(acc.Name, acc.Id);
        }
        
        for (BillWrapper bw : billWrapperList) {
            Bill__c newBill = new Bill__c();
                    newBill.Invoice_Number__c = bw.billId; 
                    //System.debug('Account Number---------' + bw.accountName);
                    //System.debug('Inv Number---------' + bw.billId);
                    Id accountId = accountNameToIdMap.get(bw.accountName);
            if (accountId != null) {
                newBill.Account__c = accountId;
            } else {
                // Handle cases where accountName is not found
                System.debug('Account not found for name: ' + bw.accountName);
            }
                    String balanceWithoutDollarSign = bw.balance.replace('$', '');
                    newBill.Balance__c = Decimal.valueOf(balanceWithoutDollarSign); 
                    billRecords.add(newBill);
        }
        
        return billRecords; 
    }
}