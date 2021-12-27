public with sharing class ContactHelper {

    public static Boolean isrunUpdateAccount = false;
    
    public static void afterInsert(Map<Id, Contact> newMapContact){
        List<Account> lstAccountUpdate = new List<Account>();
        Map<Id, Id> mapRetVal = getWorkItemIds(newMapContact.keySet());
        Map<Id, Account> mapAccount = getMapAccount(newMapContact, new Map<Id, Contact>());

        for(Contact con : newMapContact.values()){
            if(con.Active__c){
                if(mapAccount.containsKey(con.AccountId)){
                    mapAccount.get(con.AccountId).Total_Contacts__c = mapAccount.get(con.AccountId).Total_Contacts__c == null ? 0 : mapAccount.get(con.AccountId).Total_Contacts__c;
                    mapAccount.get(con.AccountId).Total_Contacts__c = mapAccount.get(con.AccountId).Total_Contacts__c + 1;
                    lstAccountUpdate.add(mapAccount.get(con.AccountId));
                }
            }
            else{
                submitForApproval(con);
            }
        }
        if(!lstAccountUpdate.isEmpty()){
            isrunUpdateAccount = true;
            update lstAccountUpdate;
        }
    }

    public static void afterUpdate(Map<Id, Contact> oldMap, Map<Id, Contact> newMap){
        List<Account> lstAccountUpdate = new List<Account>();
        Map<Id, Account> mapAccount = getMapAccount(newMap, oldMap);

        for(Contact conNew : newMap.values()){
            Account newAcc = conNew.AccountId <> null ? mapAccount.get(conNew.AccountId) : new Account();
            Account oldAcc = oldMap.get(conNew.Id).AccountId <> null ? mapAccount.get(oldMap.get(conNew.Id).AccountId) : new Account();

            // Account field changed
            if(conNew.AccountId <> oldMap.get(conNew.Id).AccountId){
                // Active field changed
                if(conNew.Active__c <> oldMap.get(conNew.Id).Active__c){
                    if(conNew.Active__c && newAcc.Id <> null){
                        newAcc.Total_Contacts__c = newAcc.Total_Contacts__c == null ? 1 : newAcc.Total_Contacts__c + 1;
                        lstAccountUpdate.add(newAcc);
                    }
                    else if(conNew.Active__c == false && oldAcc.Id <> null){
                        oldAcc.Total_Contacts__c = oldAcc.Total_Contacts__c == null ? 0 : oldAcc.Total_Contacts__c - 1;
                        lstAccountUpdate.add(oldAcc);
                    }
                }
                // Active field did not changed and Active field is TRUE
                else if(conNew.Active__c){
                    if(newAcc.Id <> null){
                        newAcc.Total_Contacts__c = newAcc.Total_Contacts__c == null ? 1 : newAcc.Total_Contacts__c + 1;
                        lstAccountUpdate.add(newAcc);
                    }
                    if(oldAcc.Id <> null){
                        oldAcc.Total_Contacts__c = oldAcc.Total_Contacts__c == null ? 0 : oldAcc.Total_Contacts__c - 1;
                    lstAccountUpdate.add(oldAcc);
                    }
                }
            }
            // Account field did not change but Active field changed
            else if(conNew.AccountId <> null){
                if(conNew.Active__c <> oldMap.get(conNew.Id).Active__c){
                    if(conNew.Active__c){
                        newAcc.Total_Contacts__c = newAcc.Total_Contacts__c == null ? 1 : newAcc.Total_Contacts__c + 1;
                    }
                    else{
                        newAcc.Total_Contacts__c = newAcc.Total_Contacts__c == null ? 0 : newAcc.Total_Contacts__c - 1;
                    }
                    lstAccountUpdate.add(newAcc);
                }
            }
        }

        if(!lstAccountUpdate.isEmpty()){
            isrunUpdateAccount = true;
            update lstAccountUpdate;
        }
    }

    public static void beforeDelete(Map<Id, Contact> oldMap){
        Map<Id, Account> mapAccount = getMapAccount(oldMap, new Map<Id, Contact>());
        List<Account> lstAccountUpdate = new List<Account>();
        for(Contact con : oldMap.values()){
            if(con.Active__c && con.AccountId <> null){
                mapAccount.get(con.AccountId).Total_Contacts__c = mapAccount.get(con.AccountId).Total_Contacts__c == null ? 0 : mapAccount.get(con.AccountId).Total_Contacts__c - 1;
                lstAccountUpdate.add(mapAccount.get(con.AccountId));
            }
        }
        if(!lstAccountUpdate.isEmpty()){
            isrunUpdateAccount = true;
            update lstAccountUpdate;
        }
    }

    private static Map<Id, Account> getMapAccount(Map<Id, Contact> newMap, Map<Id, Contact> oldMap){
        Set<Id> setAccountIds = new Set<Id>();
        for(Contact conNew : newMap.values()){
            if(conNew.AccountId <> null){
                setAccountIds.add(conNew.AccountId);
            }
            if(!oldMap.isEmpty() && oldMap.get(conNew.Id).AccountId <> null){
                setAccountIds.add(oldMap.get(conNew.Id).AccountId);
            }
        }
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, Total_Contacts__c FROM Account WHERE Id IN :setAccountIds]);
        return mapAccount;
    }

    private static Map<Id, Id> getWorkItemIds(Set<Id> setTargetObjectId){
        Map<Id, Id> mapRetVal = new Map<Id, Id>();
        for(ProcessInstanceWorkitem workItem : [SELECT p.Id, p.ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem p WHERE p.ProcessInstance.TargetObjectId IN:setTargetObjectId]){
            mapRetVal.put(workItem.ProcessInstance.TargetObjectId, workItem.Id);
        }
        return mapRetVal;
    }

    private static void submitForApproval(Contact con){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval automatically using Trigger');
        req1.setObjectId(con.Id);
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        Approval.ProcessResult result = Approval.process(req1);
    }

}