/*
Class Name: CreateExpenseReport_ExtensionController
Description: Controller Extension for Page that is used to create/edit the Expense_Report__c record by Contractor User. User can insert the related Expense_Item__c records to associate with Expense_Report__c.
*/
public with sharing class CreateExpenseReport_ExtensionController {
    //Expense_Report__c instance for DML.
    public Expense_Report__c expenseReport {get;set;}
    
    //wrapper list that saves the Expense_Item__c and record index.
    public list<wrapExpenseItem> expenseItemList {get;set;}
    
    //Index of the Expense_Item__c record on page to remove from the list.
    public Integer removeIndex {get; set;}
    
    //Flag to check whether the page is in New or Edit mode.
    public boolean isNewFlag {get;set;}
    
    //String to display as Page Header and Section Header sub-title.
    public string sectionHeaderSubTitle {get;set;}
    
    //List to get the existing Expense_Item__c record when User clicks "Remove" link on page.
    public list<Expense_Item__c> expenseItemToDeleteList {get;set;}
    
    //Used for indexing when user adds row through "Add Expense Item" button.
    public integer lastIndex {get;set;}
    
    //Inner class to bind Expense_Item__c with the index.
    public class wrapExpenseItem {
        
        //Expense_Item__c record instance
        public Expense_Item__c expenseItem {get;set;}
        
        //Integer to save the index of Expense_Item__c record/instance
        public integer recordIndex {get;set;}
        
        //Controller to assign values.
        public wrapExpenseItem(Expense_Item__c eItem, integer rIndex) {
            this.expenseItem = eItem;
            this.recordIndex = rIndex;
        }
    }
    
    //Controller of the extension.
    public CreateExpenseReport_ExtensionController(ApexPages.StandardController controller) {
        //set initial value of lastIndex to 0.
        lastIndex = 0;
        
        //set initial value of isNewFlag to true.
        isNewFlag = true;
        
        //set initial value of sectionHeaderSubTitle to 'New Expense Report'.
        sectionHeaderSubTitle = 'New Expense Report';
        
        //Check if expenseReport instance is null.
        if(expenseReport == null) {
            //initialize expenseReport
            expenseReport = new Expense_Report__c();
        }
        
        //Check if expenseItemList list is null.
        if(expenseItemList == null) {
            //initialize expenseItemList.
            expenseItemList = new list<wrapExpenseItem>();
        }
        
        //assign expenseReport value from standard controller getRecord method.
        //expenseReport will hold the values from the page.
        expenseReport = (Expense_Report__c)controller.getRecord();
        
                
        //Check if expenseReport Id is not null. This is checked to figure out whether the page is in New or Edit mode.
        if(expenseReport.Id != null) {
            //set isNewFlag to false.
            isNewFlag = false;
            
            //set sectionHeaderSubTitle to Expense_Report__c Record name
            sectionHeaderSubTitle = expenseReport.Name;
            
            //Method invoked to get the related Expense_Item__c records.
            ExpenseItems();
        }
    }
    
    //Method to get related Expense_Item__c records when the page is in Edit mode of existing Expense_Report__c record.
    public void ExpenseItems() {
        //Query to get all the related Expense_Item__c records.
        for(Expense_Item__c[] eItem : [Select Id, Name, Amount__c, Comment__c, 
                                Expense_Category__c, Expense_Date__c, Expense_Report__c, Vendor__c 
                                from Expense_Item__c 
                                where Expense_Report__c =: expenseReport.Id 
                                LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())
                                ]) {
            for(Expense_Item__c eI : eItem) {
                //Add record in expenseItemList and wrap it with the index.
                expenseItemList.add(new wrapExpenseItem(eI, lastIndex++));
            }
        }
    }
    
    //Method invoked when User clicks on "Add Expense Item" button.
    public void addExpenseItemRow() {
        if(expenseItemList.size() == 20) {
            ApexPages.Message errorMaxLinesMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Limit for Line Items reached.');
            ApexPages.addMessage(errorMaxLinesMsg);
        }
        else {
            //Add new instance of Expense_Item__c in expenseItemList and wrap it with the index.
            expenseItemList.add(new wrapExpenseItem(new Expense_Item__c(), lastIndex++));
        }
    }
    
    //Method invoked when User clicks on "Remove" link next to Expense_Item__c.
    public void removeExpenseItemRow() {
        //initialize expenseItemToDeleteList List if null.
        if(expenseItemToDeleteList == null) {
            expenseItemToDeleteList = new list<Expense_Item__c>();
        }
        
        //Loop through the expenseItemList wrap list.
        for(Integer i = 0; i < expenseItemList.size(); i++) {
            //If Record Index matches the index number selected by User from page, then remove it from list.
            if(expenseItemList[i].recordIndex == removeIndex) {
                //if the record exists for the index. applicable only in edit mode.
                if(expenseItemList[i].expenseItem.Id != null) {
                    //add Expense_Item__c record in expenseItemToDeleteList list.
                    expenseItemToDeleteList.add(expenseItemList[i].expenseItem);
                }
                
                //Remove record from list.
                expenseItemList.remove(i);
            }
        }
    }
    
    //Method invoked when user clicks "Save" button.
    public PageReference save() {
        // Create a savepoint because the data should not be committed to the database
        Savepoint sp = Database.setSavepoint();
        
        //try block
        try {
            //Check size of expenseItemList
            if(!expenseItemList.isEmpty()) {
                //boolean variable to check if any Expense_Item__c.Expense_Date__c is not filled by User.
                boolean showExpenseDateError = false;
                
                //boolean variable to check if any Expense_Item__c.Amount__c is not filled by User.
                boolean showAmountError = false;
                
                //boolean variable to check if any Expense_Item__c.Expense_Category__c is not filled by User.
                boolean showExpenseCategoryError = false;
                
                //loop through expenseItemList.
                for(wrapExpenseItem wEI: expenseItemList) {
                    //Check for null value of Expense_Item__c.Expense_Date__c
                    if(wEI.expenseItem.Expense_Date__c == null) {
                        //set boolean variable to true.
                        showExpenseDateError = true;
                        
                        //add error to the Expense_Date__c null field.
                        wEI.expenseItem.Expense_Date__c.addError('Expense Date: Required fields are missing.');
                    }
                    
                    //Check for null value of Expense_Item__c.Amount__c
                    if(wEI.expenseItem.Amount__c == null) {
                        //set boolean variable to true.
                        showAmountError = true;
                        
                        //add error to the Amount__c null field.
                        wEI.expenseItem.Amount__c.addError('Amount: Required fields are missing.');
                    }
                    
                    //Check for null value of Expense_Item__c.Expense_Category__c
                    if(wEI.expenseItem.Expense_Category__c == null) {
                        //set boolean variable to true.
                        showExpenseCategoryError = true;
                        
                        //add error to the Expense_Category__c null field.
                        wEI.expenseItem.Expense_Category__c.addError('Expense Category: Required fields are missing.');
                    }
                }
                
                //return null if any of the associated boolean flag set to true.
                if(showExpenseDateError == true || showAmountError == true || showExpenseCategoryError == true) {
                    return null;
                }
                
            }
            
            //upsert the Expense_Report__c record.
            upsert expenseReport;
            
            //if expenseItemToDeleteList size is greater than 0, then delete the records in it.
            if(expenseItemToDeleteList != null && expenseItemToDeleteList.size() > 0) {
                //Delete records.
                delete expenseItemToDeleteList;
            }
            
            if(!expenseItemList.isEmpty()) {
                list<Expense_Item__c> upsertExpenseItemList = new list<Expense_Item__c>();
                for(wrapExpenseItem wEI: expenseItemList) {
                    Expense_Item__c eItem = new Expense_Item__c();
                    eItem = wEI.expenseItem;
                    if(isNewFlag == true) {
                        eItem.Expense_Report__c = expenseReport.Id;
                    }
                    else if(eItem.Expense_Report__c == null) {
                        eItem.Expense_Report__c = expenseReport.Id;
                    }
                    upsertExpenseItemList.add(eItem);
                }
                upsert upsertExpenseItemList;
            }
        }
        //catch block
        catch(Exception e) {
            // Revert the database to the original state
            Database.rollback(sp);
            return null;
        }
        
        //navigate user to view mode of the Expense_Report__c record.
        return new Pagereference ('/' + expenseReport.Id);
    }
    
    public static testMethod void testMethod_cEREC() {
        //test record for creating Project__c object.
        Project__c projectRecord;
        
        //test record list for creating Expense_Item__c object.
        list<Expense_Item__c> expenseItemList = new list<Expense_Item__c>();
        
        //test record for creating Vendor__c object.
        Vendor__c vendorRecord;
        
        //test record for creating Expense_Category__c object.
        Expense_Category__c expenseCategoryRecord;
        
        //list to fetch Id of 'C - IT Contractor' Profile.
        list<Profile> profileContractorList = new list<Profile>();
        
        //test record for creating Contractor user.
        User userContractor;
        
                
        //get record for Profile with Name='C - IT Contractor'.
        profileContractorList = [Select Id 
                                from profile 
                                where Name = 'C - IT Contractor' 
                                LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())];
        
        //Check size of profile list.
        if(!profileContractorList.isEmpty()) {
            //test record for creating Expense_Report__c object.
            Expense_Report__c expenseReport = new Expense_Report__c();
            
            //create Project__c test data.
            projectRecord = new Project__c(Start_Date__c = System.Today(), End_Date__c = System.Today().addMonths(4), Name = 'test Project 1', Executive_Sponsor__c = Userinfo.getUserId());
            insert projectRecord;
            
            //create Expense_Category__c test data.
            expenseCategoryRecord = new Expense_Category__c(Name = 'test Expense Category');
            insert expenseCategoryRecord;
            
            //create Vendor__c test data.
            vendorRecord = new Vendor__c(Name = 'test Vendor', Expense_Total__c = 1000);
            insert vendorRecord;
            
            //Create Contractor User record.
            userContractor = new User(alias = 'cIT1', email='IT.Contractor@test.com',
                                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                    localesidkey='en_US', profileid = profileContractorList[0].Id,  
                                    timezonesidkey='America/Los_Angeles', username='IT.Contractor@test.com');
            insert userContractor;
            
            //Share Project__c record with Contractor User.
            Project__Share pShare = new Project__Share(AccessLevel = 'Read', UserOrGroupId = userContractor.Id, ParentId = projectRecord.Id);
            insert pShare;
            
            //start the test.
            test.startTest();
            
            //Change the system context to Contractor User.
            system.runAs(userContractor) {
                //AssertEquals statement to check the context of User.
                system.assertEquals(userContractor.Id, userInfo.getUserId());
                /*****************************************************************************************************************
                                                New Mode for calling Visualforce Controller Extension
                *****************************************************************************************************************/
                //Initialize the standard controller for expenseReport for adding new record.
                ApexPages.StandardController expenseReportController = new ApexPages.StandardController(expenseReport);
                
                //Initialize the controller extension.
                CreateExpenseReport_ExtensionController cEREC = new CreateExpenseReport_ExtensionController(expenseReportController);
                
                //Case 1: Add all the details in expenseReport and leave one row of Expense_Item__c blank. 
                //This will throw the error on save button for required fields of Expense_Item__c object: Expense_Date__c, Amount__c, Expense_Category__c
                
                //add data in expenseReport.
                expenseReport.Project__c = projectRecord.Id;
                expenseReport.Name = 'test Expense Report';
                expenseReport.Period_Ending_Date__c = System.today().addDays(3);
                
                //Add blank row for Expense_Item__c.
                cEREC.addExpenseItemRow();
                
                double expenseItemAmount = 0;
                //add data to Expense_Item__c list.
                for(integer i = 0; i < 3; i++) {
                    Expense_Item__c eItem = new Expense_Item__c(Expense_Date__c = System.Today(), Amount__c = 100 + i, Expense_Category__c = expenseCategoryRecord.Id, Comment__c = 'test comment');
                    expenseItemAmount += eItem.Amount__c;
                    //initilaize inner class with the Expense_Item__c data.
                    wrapExpenseItem w = New wrapExpenseItem(eItem, cEREC.lastIndex++);
                    
                    //add data in expenseItemList list.
                    cEREC.expenseItemList.add(w);
                }
                
                //AssertEquals statement to check the size of expenseItemList list.
                system.assertEquals(cEREC.expenseItemList.size(), 4);
                
                //call the Save method of extension. Since the fields are blank in one of the Expense_Item__c row, the error will be thrown and no DML will be committed.
                cEREC.save();
                
                //Case 2: Remove the blank Expense_Item__c row.
                //Assign the index of blank row.
                cEREC.removeIndex = 0;
                
                //remove the row by calling removeExpenseItemRow.
                cEREC.removeExpenseItemRow();
                
                //AssertEquals statement to check the size of expenseItemList list.
                system.assertEquals(cEREC.expenseItemList.size(), 3);
                
                //call the save method of Extension. the records will be saved to database since all the required fields are populated with data.
                cEREC.save();
                
                //AssertNotEquals statement to check cEREC.expenseReport.Id is not null.
                system.assertNotEquals(cEREC.expenseReport.Id, null);
                
                //AssertEquals for checking the Expense_Report__c.Total_Amount__c equals amount of all the expense list records.
                system.assertEquals([Select Total_Amount__c from Expense_Report__c where Id =: cEREC.expenseReport.Id LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())][0].Total_Amount__c, expenseItemAmount);
                
                /*****************************************************************************************************************
                                                Edit Mode for calling Visualforce Controller Extension
                *****************************************************************************************************************/
                //Case 1: Leave one row of Expense_Item__c blank. 
                //This will throw the error on save button for required fields of Expense_Item__c object: Expense_Date__c, Amount__c, Expense_Category__c
 
                //Initialize the standard controller for expenseReport in Edit mode.
                ApexPages.StandardController expenseReportControllerEdit = new ApexPages.StandardController(expenseReport);
                
                //Initialize the extension Controller.
                CreateExpenseReport_ExtensionController cERECedit = new CreateExpenseReport_ExtensionController(expenseReportControllerEdit);
                
                //Remove the 1st record from Expense_Item__c list for deletion.
                cERECedit.removeIndex = 0;
                cERECedit.removeExpenseItemRow();
                
                //AssertEquals statement to check the size of expenseItemToDeleteList list after removing 1 row.
                system.assertEquals(cERECedit.expenseItemToDeleteList.size(), 1);
                
                //Deduct Amount of removed record from variable.
                expenseItemAmount -= cERECedit.expenseItemToDeleteList[0].Amount__c;
                //AssertEquals statement to check the size of expenseItemList list after removing 1 row.
                system.assertEquals(cERECedit.expenseItemList.size(), 2);
                
                //Add new data for creation in Expense_Item__c.
                Expense_Item__c eItemEdit = new Expense_Item__c(Expense_Date__c = System.Today(), Vendor__c = vendorRecord.Id, Amount__c = 100, Expense_Category__c = expenseCategoryRecord.Id);
                expenseItemAmount += eItemEdit.Amount__c;
                
                //initialize the Expense_Item__c data with inner class.
                wrapExpenseItem wEdit = New wrapExpenseItem(eItemEdit, cERECedit.lastIndex++);
                
                //add the row in expenseItemList list.
                cERECedit.expenseItemList.add(wEdit);
                system.debug(cERECedit.expenseItemList.size());
                //AssertEquals statement to check the size of expenseItemList list after adding 1 row.
                system.assertEquals(cERECedit.expenseItemList.size(), 3);
                
                //Add blank row for Expense_Item__c.
                cEREC.addExpenseItemRow();
                
                //call the Save method of extension. Since the fields are blank in one of the Expense_Item__c row, the error will be thrown and no DML will be committed.
                cERECedit.save();
                
                //Case 2: Remove the blank Expense_Item__c row.
                //Assign the index of blank row.
                cERECedit.removeIndex = cERECedit.lastIndex;
                
                //remove the row by calling removeExpenseItemRow.
                cERECedit.removeExpenseItemRow();
                
                //AssertEquals statement to check the size of expenseItemList list after removing 1 row.
                system.assertEquals(cERECedit.expenseItemList.size(), 3);
                
                //call the save method of Extension. the records will be saved to database since all the required fields are populated with data.
                cEREC.save();
                
                //AssertEquals for checking the Expense_Report__c.Total_Amount__c equals amount of all the expense list records.
                system.assertEquals([Select Total_Amount__c from Expense_Report__c where Id =: cEREC.expenseReport.Id LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())][0].Total_Amount__c, expenseItemAmount);
                
                
                //Case 3: User clicks on "Edit" button and is navigated to Visuaforce page in edit mode.
                //User removes Expense_Item__c row. However, user clicks Cancel button.
                //Initialize Expense_Report__c standard controller.
                ApexPages.StandardController expenseReportControllerCancelEdit = new ApexPages.StandardController(expenseReport);
                
                //take the previos record with item rows. remove one existing row and then call cancel. assert number of rows.
                //initialize controller extension.
                CreateExpenseReport_ExtensionController cERECCancelEdit = new CreateExpenseReport_ExtensionController(expenseReportControllerCancelEdit);
                
                //Remove the 1st record from Expense_Item__c list for deletion.
                cERECCancelEdit.removeIndex = 0;
                cERECCancelEdit.removeExpenseItemRow();
                
                //Call "Cancel" method.
                expenseReportControllerCancelEdit.Cancel();
                
                //AssertEquals for checking the number of Expense_Item__c rows for Expense_Report__c.
                //removeExpenseItemRow should not affect the number of rows since User clicked Cancel button.
                system.assertEquals([Select Count() from Expense_Item__c where Expense_Report__c =: cERECCancelEdit.expenseReport.Id LIMIT : (limits.getLimitQueryRows() - limits.getQueryRows())], 3);
                
                /*****************************************************************************************************************
                                                New Mode for calling Visualforce Controller Extension
                *****************************************************************************************************************/
                //Case 1: Do not populate Expense_Report__c.Project__c.
                //This will throw an exception of validation rule that for Contractor User, Project__c is required field.
                
                //initialize new Expense_Report__c.
                Expense_Report__c eRepExc = new Expense_Report__c();
                
                //Initialize Expense_Report__c standard controller.
                ApexPages.StandardController expenseReportControllerException = new ApexPages.StandardController(eRepExc);
                
                //initialize controller extension.
                CreateExpenseReport_ExtensionController cERECExc = new CreateExpenseReport_ExtensionController(expenseReportControllerException);
                
                //add data to Expense_Report__c,
                eRepExc.Name = 'test Expense Report';
                eRepExc.Period_Ending_Date__c = System.today().addDays(3);
                
                //assertEquals statement to check that Project__c is null.
                system.assertEquals(eRepExc.Project__c, null);
                
                //call save method of extension, this will throw the validation rule error.
                cERECExc.save();
                
                //Case 2:  try adding more than 20 Expense_Item__c rows. 
                //Since a user can add maximum of 20 Expense_Item__c record, the error should be thrown when User tries to add more than 20 items.
                //add blank Expense_Item__c rows.
                for(integer i=0; i <= 20; i++) {
                    //Add blank row for Expense_Item__c.
                    cERECExc.addExpenseItemRow();
                }
                
                //assertEquals statement to check size of expenseItemList list.
                system.assertEquals(cERECExc.expenseItemList.size(), 20);
                
                //Clear the expenseItemList list
                cERECExc.expenseItemList.clear();
                
                //assertEquals statement to check size of expenseItemList list.
                system.assertEquals(cERECExc.expenseItemList.size(), 0);
                
                //Case 3: populate the Project__c field.
                //populate the Project__c field.
                eRepExc.Project__c = projectRecord.Id;
                
                //call save method of extension, this will save the record.
                cERECExc.save();
                
                //AssertNotEquals statement to check cERECExc.expenseReport.Id is not null.
                system.assertNotEquals(cERECExc.expenseReport.Id, null);
                
                //AssertNotEquals statement to check cERECExc.expenseReport.Project__c is not null.
                system.assertNotEquals(cERECExc.expenseReport.Project__c, null);
                
                //Case 3: User clicks on New button and is navigated to Visuaforce page in new mode.
                //However, user clicks Cancel button.
                //initialize new Expense_Report__c.
                Expense_Report__c eRepCancel = new Expense_Report__c();
                
                //Initialize Expense_Report__c standard controller.
                ApexPages.StandardController expenseReportControllerCancel = new ApexPages.StandardController(eRepCancel);
                
                //take the previos record with item rows. remove one existing row and then call cancel. assert number of rows.
                //initialize controller extension.
                CreateExpenseReport_ExtensionController cERECCancel = new CreateExpenseReport_ExtensionController(expenseReportControllerCancel);
                expenseReportControllerCancel.Cancel();
                
            }
            //stop test.
            test.stopTest();
        }
    }
}