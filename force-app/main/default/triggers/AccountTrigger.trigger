trigger AccountTrigger on Account (before insert, after update) {
    if(trigger.isAfter && trigger.isUpdate){
        for(Account acc : Trigger.newMap.values()){
            if(acc.Total_Contacts__c <> Trigger.oldMap.get(acc.Id).Total_Contacts__c && !ContactHelper.isrunUpdateAccount){
                acc.addError('Don\'t change Total Contacts \'s value');
            }
        }
    }
}