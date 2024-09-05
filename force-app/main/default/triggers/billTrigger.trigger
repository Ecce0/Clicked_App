// //Salesforce CLI Command to create trigger:
// //sf apex generate trigger --name billTrigger  --event 'before insert,after insert' --sobject Bill__c --output-dir force-app/main/default/triggers//

trigger billTrigger on Bill__c (before insert, after insert) {
    if(Trigger.isBefore) { 
        for (Bill__c bill: Trigger.new) {
            if (bill.Account__c == null) {
                bill.Account__c.addError('The Account number is required');
            }

            if (bill.Invoice_Number__c == null) {
                UUID randomUuid = UUID.randomUUID();
                bill.Invoice_Number__c = UUID.randomUUID().toString().substring(0, 24);
                System.debug('---before insertion complete and working');
            }
        }
    }
  

    if (Trigger.isAfter) {
      // Collect a map of Account IDs to Bill records
    Set<Id> accountIds = new Set<Id>();
    for (Bill__c bill : Trigger.new) {
        if (bill.Account__c != null) {
            accountIds.add(bill.Account__c);
        }
    }

    // Query for existing opportunities related to these accounts
    Map<Id, List<Opportunity>> accountOpportunityMap = new Map<Id, List<Opportunity>>();
    if (!accountIds.isEmpty()) {
        List<Opportunity> opportunities = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE AccountId IN :accountIds
        ];
        
        // Group opportunities by AccountId
        for (Opportunity opp : opportunities) {
            if (!accountOpportunityMap.containsKey(opp.AccountId)) {
                accountOpportunityMap.put(opp.AccountId, new List<Opportunity>());
            }
            accountOpportunityMap.get(opp.AccountId).add(opp);
        }
    }

    // Prepare list of opportunities to create
    List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

    // Iterate through Bill__c records to check for accounts with no opportunities
    for (Bill__c bill : Trigger.new) {
        // Check if the account has opportunities
        if (bill.Account__c != null && !accountOpportunityMap.containsKey(bill.Account__c)) {
            // Query for Account Name since it's needed for the Opportunity name
            Account relatedAccount = [SELECT Id, Name FROM Account WHERE Id = :bill.Account__c LIMIT 1];

            // Create a new Opportunity if the Account has no opportunities
            Opportunity newOpportunity = new Opportunity();
            newOpportunity.AccountId = bill.Account__c;
            newOpportunity.Amount = bill.Balance__c; // Set the opportunity amount to the bill balance
            newOpportunity.Name = relatedAccount.Name + ' - Opportunity ' + bill.Invoice_Number__c; // Opportunity name format
            newOpportunity.StageName = 'Prospecting'; // Example default stage (you can change this)
            newOpportunity.CloseDate = Date.today().addMonths(1); // Set default close date (1 month from today)

            // Add to the list of opportunities to insert
            opportunitiesToInsert.add(newOpportunity);
        }
    }

    // Insert new opportunities if any
    if (!opportunitiesToInsert.isEmpty()) {
        insert opportunitiesToInsert;
    }
    }
}