/**
 * @description Trigger on Client_Household__c for review date scheduling
 * @author BlackRoad OS
 */
trigger HouseholdTrigger on Client_Household__c (before insert, before update) {

    for (Client_Household__c hh : Trigger.new) {
        // Set next review date if not set or last review date changed
        Boolean isNew = Trigger.isInsert;
        Boolean reviewDateChanged = Trigger.isUpdate &&
            hh.Last_Review_Date__c != Trigger.oldMap.get(hh.Id).Last_Review_Date__c;

        if (isNew || reviewDateChanged) {
            if (hh.Next_Review_Date__c == null || reviewDateChanged) {
                hh.Next_Review_Date__c = HouseholdService.calculateNextReviewDate(hh);
            }
        }

        // Calculate annual fee if AUM changed
        if (hh.Total_AUM__c != null) {
            Boolean aumChanged = isNew ||
                (Trigger.isUpdate && hh.Total_AUM__c != Trigger.oldMap.get(hh.Id).Total_AUM__c);

            if (aumChanged && hh.Annual_Fee__c == null) {
                hh.Annual_Fee__c = HouseholdService.calculateAnnualFee(hh.Total_AUM__c);
            }
        }
    }
}
