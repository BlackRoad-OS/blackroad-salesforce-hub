/**
 * @description Trigger on Financial_Account__c to keep household AUM in sync
 * @author BlackRoad OS
 */
trigger FinancialAccountTrigger on Financial_Account__c (after insert, after update, after delete) {

    Set<Id> householdIds = new Set<Id>();

    // Collect affected household IDs
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Financial_Account__c acct : Trigger.new) {
            if (acct.Household__c != null) {
                householdIds.add(acct.Household__c);
            }
        }
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
        for (Financial_Account__c acct : Trigger.old) {
            if (acct.Household__c != null) {
                householdIds.add(acct.Household__c);
            }
        }
    }

    // Recalculate household AUM
    if (!householdIds.isEmpty()) {
        HouseholdService.recalculateHouseholds(householdIds);
    }
}
