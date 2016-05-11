/*
Trigger Name: updateProjectExpenseSpendsOnApproval
Object Name: Expense_Report__c
Description: Trigger to update Project__c.Contractor_E xpense_Spend_Approved__c field 
when Expense_Report__c is approved. The Expense_Report__c record should be of Contractor.
*/
trigger updateProjectExpenseSpendsOnApproval on Expense_Report__c (after update) {
    //Set of Expense_Report__c record Ids.
    set<Id> expenseReportIdSet = new set<Id>();
    //Project list 
    list<Project__c> projectList = new list<Project__c>();
    list<Profile> ProfileList = new list<Profile>();
    
    //Loop through the Expense_Report__c records
    for(Expense_Report__c eReport : Trigger.new) {
        //Project__c is not null and Total_Amount__c is not equal to zero and Status__c field updated to 'Approved',
        //then add record Id in expenseReportIdSet.
        if(eReport.Project__c != null && eReport.Total_Amount__c != 0 && eReport.Status__c == 'Approved' && eReport.Status__c != trigger.oldmap.get(eReport.Id).Status__c) {
            expenseReportIdSet.add(eReport.Id);
        }
    }
    
    //Check whether expenseReportIdSet set is empty.
    if(!expenseReportIdSet.isEmpty()) {
        //Get Profile record for IT Contractor
        ProfileList = [Select Id 
                        from Profile 
                        where Name = 'C - IT Contractor' 
                        LIMIT 1];
        // Create a savepoint because the data should not be committed to the database.
        Savepoint sp = Database.setSavepoint();
        //Check size of ProfileList list.
        if(!ProfileList.isEmpty()) {
            //Assign Profile Id to contractorProfileId variable.
            Id contractorProfileId = ProfileList[0].Id;
            
            //try block
            try {
                
                //Get Aggregated result for Expense_Report__c object. 
                //Group by Project__c and Project__c.Contractor_Expense_Spend_Approved__c and Sum of Total_Amount__c
                //Get records with Id in expenseReportIdSet AND Owner's Profile Id is IT Contractor
                //AND Total_Amount__c is not 0. Data should be grouped by Project__c
                List<AggregateResult> groupedExpenseReportResults = [SELECT Project__c, MAX(Project__r.Contractor_Expense_Spend_Approved__c)maxCESA, SUM(Total_Amount__c)sumTA 
                                                        FROM Expense_Report__c 
                                                        where Owner.ProfileId =: contractorProfileId  
                                                        AND Id in: expenseReportIdSet 
                                                        AND Total_Amount__c != 0
                                                        group by Project__c 
                                                        LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())];
                
                //Check size of aggregated result groupedExpenseReportResults list.
                if(!groupedExpenseReportResults.isEmpty()) {
                    //Loop through the aggregate list.
                    for(AggregateResult gER: groupedExpenseReportResults) {
                        //Add Project record in ProjectList list.
                        //Id is assigned the value of Project__c from Aggregate result query.
                        //Contractor_Expense_Spend_Approved__c is equal to addition of Contractor_Expense_Spend_Approved__c and sum of Total_Amount__c.
                        ProjectList.add(new Project__c(Id = string.valueOf(gER.get('Project__c')), Contractor_Expense_Spend_Approved__c = (gEr.get('maxCESA') != null ? double.valueOf(gEr.get('maxCESA')):0) +double.valueOf(gEr.get('sumTA'))));
                    }
                    //Update ProjectList
                    update ProjectList;
                    
                    //Clear aggregate list
                    groupedExpenseReportResults.clear();
                    
                    //Clear projectList list
                    projectList.clear();
                }
            }
            catch(Exception e) {
                // Revert the database to the original state.
                Database.rollback(sp);
            }
        }
        //Clear expenseReportIdSet Set.
        expenseReportIdSet.clear();
    }
}