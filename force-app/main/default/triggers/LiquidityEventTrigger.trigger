/**
 * @description Trigger on Liquidity_Event__c to calculate taxes and net proceeds
 * @author BlackRoad OS
 */
trigger LiquidityEventTrigger on Liquidity_Event__c (before insert, before update) {

    for (Liquidity_Event__c evt : Trigger.new) {
        // Calculate estimated tax
        if (evt.Gross_Proceeds__c != null && evt.Gross_Proceeds__c > 0) {
            evt.Estimated_Tax__c = LiquidityEventService.calculateEstimatedTax(evt);
            evt.Net_Proceeds__c = LiquidityEventService.calculateNetProceeds(evt);
        }
    }
}
