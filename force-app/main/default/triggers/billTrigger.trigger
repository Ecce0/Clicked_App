//Salesforce CLI Command to create trigger:
//sf apex generate trigger --name billTrigger  --event 'before insert,after insert' --sobject Bill__c --output-dir force-app/main/default/triggers//

trigger billTrigger on Bill__c (before insert, after insert) {
    /** Line 6 is the code to check info before update/new/etc. records */
    if(Trigger.isBefore) { 
    for (Bill__c bill: Trigger.new) {
        /** everything below this line is for all new inserts on the 
         * specific record of the stated object (Bill__c in 
         * this case) */
        if (bill.Account__c == '' || bill.Account__c == null) {
            bill.Account__c.addError('The Account number is required');
        }

        //if (bill.Invoice_Number__c.length == 0 || bill.Invoice_Number__c == null) {
        if (bill.Invoice_Number__c == null) {
            /** to create a random number:
             * UUID randomUuid = UUID.randomUUID();
                System.debug(randomUuid); 
                https://kevanmoothien.medium.com/generating-uuids-in-apex-spring-24-release-acbf1d0bc6fc
            */
            
            bill.Invoice_Number__c = UUID.randomUUID().toString().substring(0, 25);
        }
    }

        // Line 27 is the code to check info after update/new/etc. records */
        //Everything below came from chatGPT. I wasn't sure where to find the documentation
        //on how to create new records from another object outside of the trigger-based object
        if (Trigger.isAfter) {
            List<Opportunity> opportunitiesToCreate = new List<Opportunity>();
    
            for (Bill__c bill : Trigger.new) {
                // Check if the Bill has an associated Account
                if (bill.Account__c != null) {
                    
                    // Query for open Opportunities related to the Bill's Account
                    List<Opportunity> openOpportunities = [SELECT Id FROM Opportunity WHERE AccountId = :bill.Account__c AND IsClosed = false LIMIT 1];
    
                    // If there are no open Opportunities, create a new one
                    if (openOpportunities.isEmpty()) {
                        Opportunity opp = new Opportunity();
                        opp.AccountId = bill.Account__c;
                        opp.Amount = bill.Balance__c; // Assuming Balance__c is a field on the Bill__c object
                        opp.StageName = 'Prospecting'; // Default stage for a new Opportunity
                        opp.CloseDate = Date.today().addMonths(1); // Set a default Close Date
                        opp.Name = bill.Account__r.Name + ' - Opportunity ' + bill.Invoice_Number__c; // Assuming Invoice_Number__c is a field on Bill__c
    
                        opportunitiesToCreate.add(opp);
                    }
                }
            }
        }
    }
}