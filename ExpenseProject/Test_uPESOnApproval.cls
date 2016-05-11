/*
Class Name: Test_uPESOnApproval
Description: Test class for trigger updateProjectExpenseSpendsOnApproval on Expense_Report__c.
*/
@isTest
private class Test_uPESOnApproval {
    //test method begins.
    static testMethod void UnitTest_Method() {
        //test record for creating Project__c object.
        Project__c projectRecord;
        
        list<Expense_Report__c> expenseReportList = new list<Expense_Report__c>();
        
        //test record list for creating Expense_Item__c object.
        list<Expense_Item__c> expenseItemList = new list<Expense_Item__c>();
        
        //test record for creating Vendor__c object.
        Vendor__c vendorRecord;
        
        //test record for creating Expense_Category__c object.
        Expense_Category__c expenseCategoryRecord;
        
        //map of string and Id to get the User Role records. User Role Name is key and User Role Id is value.
        map<String, Id> userRoleMap = new map<String, Id>();
        
        //map of string and Id to get the Profile records. Profile Name is key and Profile Id is value.
        map<String, Id> profileMap = new map<String, Id>();
        
        //Approval ProcessResult variable.
        Approval.ProcessResult[] result1 = new Approval.ProcessResult[]{};
        
        //test record for creating Manager user.
        User userManager;
        
        //test record for creating Contractor user.
        User userContractor;
        
        //get the User role records where Name is either 'IT - Contractor' or 'IT - Manager'.
        for(UserRole[] uRole : [Select u.Name, u.Id 
                                From UserRole u 
                                where u.Name in ('IT - Contractor', 'IT - Manager') 
                                LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())]) {
            //put the values in map.
            for(UserRole uR : uRole) {
                userRoleMap.put(uR.Name, uR.Id);
            }
        }
        
        //get the Profile records where Name is either 'C - IT Contractor' or 'C - IT Manager'.
        for(Profile[] uProfile : [Select p.Name, p.Id 
                                From Profile p 
                                where p.Name in ('C - IT Contractor', 'C - IT Manager') 
                                LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())]) {
            //put the values in map.
            for(Profile p : uProfile) {
                profileMap.put(p.Name, p.Id);
            }
        }
        
        //check size of profileMap and userRoleMap maps.
        if(!profileMap.isEmpty() && !userRoleMap.isEmpty()) {
            //Create Manager User record.
            userManager = new User(alias = 'cIT1', email='IT.ManagerUrbananaTest@Urbanana.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileMap.get('C - IT Manager'), 
                timezonesidkey='America/Los_Angeles', username='IT.ManagerUrbananaTest@Urbanana.com' , UserRoleId = userRoleMap.get('IT - Manager'));
                
            insert userManager;
            
            //AssertNotEquals statement to check userManager.Id is not null.
            system.assertNotEquals(userManager.Id, null);
            
            //Create Contractor User record.
            userContractor = new User(alias = 'cIT1', email='IT.ContractorUrbananaTest@Urbanana.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = profileMap.get('C - IT Contractor'), ManagerId = userManager.Id, 
            timezonesidkey='America/Los_Angeles', username='IT.ContractorUrbananaTest@Urbanana.com', UserRoleId = userRoleMap.get('IT - Contractor'));
            insert userContractor;
            
            //AssertNotEquals statement to check userContractor.Id is not null.
            system.assertNotEquals(userContractor.Id, null);
            
            //AssertEquals statement to check userContractor.ManagerId equal to userManager.Id.
            system.assertEquals(userContractor.ManagerId, userManager.Id);
            
            //Instantiate the curent User.
            User thisUser = new User(Id = UserInfo.getUserId());
            
            //Start test.
            test.startTest();
            //Change the context to current User to avoid exception of setup and non-setup DML exception.
            system.runAs(thisUser) {
                //create Project__c test data.
                projectRecord = new Project__c(Contractor_Expense_Spend_Approved__c = 0, Start_Date__c = System.Today(), Name = 'test Project');
                insert projectRecord;

                //create Expense_Category__c test data.
                expenseCategoryRecord = new Expense_Category__c(Name = 'test Expense Category');
                insert expenseCategoryRecord;
            
                //create Vendor__c test data.
                vendorRecord = new Vendor__c(Name = 'test Vendor');
                insert vendorRecord;
                
                //Share Project__c record with Manager User.
                Project__Share pShareManager = new Project__Share(AccessLevel = 'Edit', UserOrGroupId = userManager.Id, ParentId = projectRecord.Id);
                insert pShareManager;
                
                //Share Project__c record with Contractor User.
                Project__Share pShareContractor = new Project__Share(AccessLevel = 'Read', UserOrGroupId = userContractor.Id, ParentId = projectRecord.Id);
                insert pShareContractor;
            }
            
            //change the context to Contractor User.
            system.runAs(userContractor) {
                //AssertEquals statement to check current User logged in is userContractor.
                system.assertEquals(userContractor.Id, UserInfo.getUserId());
                
                //create records for Expense_Report__c.
                for(integer i = 0; i < 5; i++) {
                    expenseReportList.add(new Expense_Report__c(Project__c = projectRecord.Id, Name = 'test Expense Report' + i, Period_Ending_Date__c = System.today().addDays(i)));
                }
                insert expenseReportList;
                
                //loop through the created Expense_Report__c records.
                for(Expense_Report__c expenseReport : expenseReportList) {
                    //add Expense_Item__c records for each Expense_Report__c record.
                    for(integer i = 0; i < 10; i++) {
                        Expense_Item__c eItem = new Expense_Item__c(Expense_Report__c = expenseReport.Id, Expense_Date__c = System.Today(), Amount__c = 100, Expense_Category__c = expenseCategoryRecord.Id, Vendor__c = vendorRecord.Id);
                        expenseItemList.add(eItem);
                    }
                }
                //insert Expense_Item__c records.
                insert expenseItemList;
                
                //submit the records for approval.
                for(Expense_Report__c expenseReport : expenseReportList) {
                    // Create an approval request for the Expense_Report__c     
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setComments('Submitting request for approval.');
                    req1.setObjectId(expenseReport.Id);
    
                    // Submit the approval request for the Expense_Report__c  
                    result1.add(Approval.process(req1));
                }
                
            }
            
            //change the context to Manager User.
            system.runAs(userManager){
                //AssertEquals statement to check current User logged in is userManager.
                system.assertEquals(userManager.Id, UserInfo.getUserId());
                
                Approval.ProcessWorkitemRequest[] req21 = new Approval.ProcessWorkitemRequest[]{};
                
                //approve/reject the records.
                for(integer i=0; i<result1.size();i++){
                    // First, get the ID of the newly created item    
                    List<Id> newWorkItemIds = result1[i].getNewWorkitemIds();
                    
                    // Instantiate the new ProcessWorkitemRequest object and populate it  
                    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                    //reject 1st record
                    if(i != 0) {
                        req2.setComments('Approving request.');
                        req2.setAction('Approve');
                        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                    }
                    //approve rest of the records.
                    else {
                        req2.setComments('Rejecting request.');
                        req2.setAction('Reject');
                    }
                    req2.setWorkitemId(newWorkItemIds.get(0));
                    req21.add(req2);
                }
                //Approve/Reject the records.
                Approval.ProcessResult[] result2 =  Approval.process(req21);
                
                //get the sum of all Expense_Report__c.Total_Amount__c that were approved for Project__c record.
                List<AggregateResult> groupedExpenseReportResults = [SELECT Project__c, SUM(Total_Amount__c)sumTA 
                                                        FROM Expense_Report__c 
                                                        where OwnerId =: userContractor.Id   
                                                        AND Project__c =: projectRecord.Id 
                                                        AND Total_Amount__c != 0 
                                                        AND Status__c = 'Approved' 
                                                        group by Project__c 
                                                        LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())];
                if(!groupedExpenseReportResults.isEmpty()) {
                    //assert statement to check the value of Project__c.Contractor_Expense_Spend_Approved__c equals the result of aggregate query above.
                    system.assertEquals([Select Contractor_Expense_Spend_Approved__c from Project__c where Id=:projectRecord.Id][0].Contractor_Expense_Spend_Approved__c, groupedExpenseReportResults[0].get('sumTA'));
                }
            }
            //stop test.
            test.stopTest();
        }
    }
}