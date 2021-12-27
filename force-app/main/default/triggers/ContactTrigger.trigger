trigger ContactTrigger on Contact (after insert, after update, before delete) {

    if(Trigger.isAfter && Trigger.isInsert){
        ContactHelper.afterInsert(Trigger.newMap);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        ContactHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if(Trigger.isBefore && Trigger.isDelete){
        ContactHelper.beforeDelete(Trigger.oldMap);
    }

}