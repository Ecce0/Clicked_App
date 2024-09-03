public with sharing class BillBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public List<Id> receivesBillByEmail = new List<Id>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // This method will query all active accounts that have a value for Bill_By_Email__c.
        // Hint: In your dynamic query, remember to escape the single quotes around 'Yes'.
        // Use the Database.getQueryLocator(String) method to return the result.
        // Query for the following fields: Id, Bill_By_Email__c.
        // Learn more about QueryLocator: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Database_QueryLocator.htm
     String query = 'SELECT Id, Bill_By_Email__c FROM Account WHERE Bill_By_Email__c = \'Yes\'';
            return Database.getQueryLocator(query);
        }
    

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // This method processes the queried records. It prepares a list of account IDs (this.receivesBillByEmail)
        // to carry over to the finish method. We do this by iterating over 'scope' and checking whether
        // Bill_By_Email__c is TRUE. This method will also call our BillAPI.getBills() method.
        // Learn more about Batch Apex: https://trailhead.salesforce.com/content/learn/modules/asynchronous_apex/async_apex_batch
            for (Account acc : scope) {
                // 2. Check if Bill_By_Email__c is TRUE
                if (acc.Bill_By_Email__c == true) {
                    // 3. Add the account Id to the receivesBillByEmail list
                    this.receivesBillByEmail.add(acc.Id);
                }
            }
            
            // 4. Call the BillAPI.getBills() method
            BillAPI.getBills();
        }
    

    public void finish(Database.BatchableContext bc) {
        // This is the final method of the class, called after all processing in the start and execute methods is complete.
        // We use this method to send an email to each customer in the receivesBillByEmail list.

        // First, query for the recently created bills for each account using a nested query:
        // [SELECT Id, (SELECT Id FROM Bills__r ORDER BY CreatedDate DESC) FROM Account WHERE Id IN :this.receivesBillByEmail]

        // Next, iterate over the results of this query and associate the ID of the most recent bill with the
        // corresponding account ID in a Map<Id, Id> called billMap, using the .put(Id, Id) method of the Map class.
        // Learn more about Maps: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_map.htm

        // Create a Map<Id, String> called emailMap, where we'll hold the Account ID and account email.

        // Prepare to call our BillEmailer.sendEmails(Map<String, Blob> emailsWithBills) method.
        // The String in the map, called sendMap, will be the Account.Email__c field, and the Blob will be the PDF attachment.

        // Generate a PDF for each bill ID using:
        // PageReference pageRef = new PageReference('/apex/BillVFP?id=' + [BILLID]);
        // Blob pdfBlob = pageRef.getContentAsPDF();
        // You'll need to use the .get() method of the Map class to retrieve values.

        // Finally, call our BillEmailer.sendEmails(sendMap) method. This method is VOID, so there will be no return value.
        // Learn more about generating PDFs: https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_controller_sosc_output_pdf.htm
        // 1. Query for the recently created bills for each account
        List<Account> accountsWithBills = [SELECT Id, 
                                           (SELECT Id FROM Bills__r ORDER BY CreatedDate DESC) 
                                           FROM Account 
                                           WHERE Id IN :this.receivesBillByEmail];

        // 2. Map to associate the most recent bill ID with the corresponding account ID
        Map<Id, Id> billMap = new Map<Id, Id>();

        // 3. Map to hold the Account ID and account email
        Map<Id, String> emailMap = new Map<Id, String>();

        // 4. Prepare to call BillEmailer.sendEmails by creating the Map<String, Blob> sendMap
        Map<String, Blob> sendMap = new Map<String, Blob>();

        // 5. Iterate over the results of the query
        for (Account acc : accountsWithBills) {
            if (!acc.Bills__r.isEmpty()) {
                // Get the most recent bill ID
                Id billId = acc.Bills__r[0].Id;

                // Associate the bill ID with the account ID in billMap
                billMap.put(acc.Id, billId);

                // Store the account's email in emailMap
                emailMap.put(acc.Id, acc.Email__c);
            }
        }

        // 6. Generate a PDF for each bill ID and prepare sendMap
        for (Id accId : billMap.keySet()) {
            Id billId = billMap.get(accId);
            String email = emailMap.get(accId);

            if (email != null) {
                // Generate the PDF for the bill
                PageReference pageRef = new PageReference('/apex/BillVFP?id=' + billId);
                Blob pdfBlob = pageRef.getContentAsPDF();

                // Put the email and corresponding PDF in sendMap
                sendMap.put(email, pdfBlob);
            }
        }

        // 7. Call the BillEmailer.sendEmails method to send the emails with attached PDFs
        BillEmailer.sendEmails(sendMap);
    }
}
