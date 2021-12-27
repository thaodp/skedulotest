global with sharing class SearchAccountAndContactController {
    public String keySearch {get; set;}
    public static List<Result> lstResult {get; set;}
    public Boolean isShow {get; set;}

    public SearchAccountAndContactController() {
        keySearch = '';
        lstResult = new List<Result>();
        isShow = false;
    }

    public void searchData(){
        lstResult = new List<Result>();
        isShow = false;
        if(!String.isBlank(keySearch)){
            keySearch = '%' + keySearch + '%';
            //String strQuery = 'FIND \'*' + keySearch + '*\' IN NAME FIELDS RETURNING  Account (Id,Name), Contact (Id,Name)';
            //List<List <sObject>> searchList = search.query(strQuery);
            // ((List<Account>)searchList[0])
            for(Account acc : [SELECT Id, Name, Counter__c FROM Account WHERE Name LIKE :keySearch LIMIT 50000]){
                lstResult.add(new Result('Account', acc, new Contact()));
            }
            // ((List<Contact>)searchList[1])
            for(Contact con : [SELECT Id, Name, Counter__c FROM Contact WHERE Name LIKE :keySearch LIMIT 50000]){
                lstResult.add(new Result('Contact', new Account(), con));
            }

            if(lstResult.size() == 0){
                ApexPages.addmessage(new apexpages.message(apexpages.severity.Warning, 'No found record'));
                return;
            }
            else{
                isShow = true;
            }
        }
        else{
            ApexPages.addmessage(new apexpages.message(apexpages.severity.Error, 'Please enter search word'));
            return;
        }
    }

    @RemoteAction
    global static Result updateCounter(Result rdUpdate){
        Result recordUpt = new Result();
        try{
            if(rdUpdate.RecordType == 'Account'){
                Account acc = new Account();
                acc.Id = Id.valueOf(rdUpdate.RecordId);
                acc.Counter__c = rdUpdate.RecordCounter + 1;
                System.debug('ACC : ' + acc);
                update acc;
                recordUpt = new Result('Account', acc, new Contact());
            }
            else if(rdUpdate.RecordType == 'Contact'){
                Contact con = new Contact();
                con.Id = rdUpdate.RecordId;
                con.Counter__c = Integer.valueOf(rdUpdate.RecordCounter)+ 1;
                update con;
                recordUpt = new Result('Contact', new Account(), con);
            }
        }
        catch(DMLException ex){
            System.debug('EX : ' + ex.getMessage());
        }
        return recordUpt;
    }

    global class Result{
        public String RecordName {get; set;}
        public String RecordType {get; set;}
        public String RecordId {get; set;}
        public Decimal RecordCounter {get; set;}
        public Result(){
            this.RecordName = '';
            this.RecordType = '';
            this.RecordId = '';
            this.RecordCounter = 0;
        }
        public Result(String objName, Account acc, Contact con){
            if(objName == 'Account'){
                this.RecordName = acc.Name;
                this.RecordType = 'Account';
                this.RecordId = acc.Id;
                this.RecordCounter = acc.Counter__c == null ? 0 : acc.Counter__c;
            }
            if(objName == 'Contact'){
                this.RecordName = con.Name;
                this.RecordType = 'Contact';
                this.RecordId = con.Id;
                this.RecordCounter = con.Counter__c == null ? 0 : con.Counter__c;
            }
        }
    }
}