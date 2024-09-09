BillBatch batch = new BillBatch(); 
id batchId = Database.executeBatch(batch);
System.debug(batchId);
BillScheduler billS = new BillScheduler();
System.debug(billS);