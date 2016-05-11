global with sharing class controllerCls {

    
    public List<Opportunity> getAccounts(){
        return [Select Id,Name,Amount from Opportunity limit 1000];
    }
    @remoteAction
    global static string getAccountsJSON(){
        List<Opportunity> accounts = [Select Id,Name,Amount,Account.Name,Description,CloseDate from Opportunity order by createdDate Asc];
        String accountsJSON = JSON.serializePretty(accounts);
        return accountsJSON;
    }
    @remoteAction
    global static string updateAccount(String Ac){
        System.debug('>>>>>'+Ac);

        Opportunity accountsDeserialized = (Opportunity) JSON.deserializeStrict(Ac, Opportunity.class);
        System.debug('>>>>>'+accountsDeserialized);
        update accountsDeserialized;
         System.debug('>>>>>'+accountsDeserialized);
        return accountsDeserialized.Id;
    }
     @remoteAction
    global static string deleteAccount(String Ac){
        System.debug('>>>>>'+Ac);

        Opportunity accountsDeserialized = (Opportunity) JSON.deserializeStrict(Ac, Opportunity.class);
        System.debug('>>>>>'+accountsDeserialized);
        delete accountsDeserialized;
        return 'sucess';
    }
}