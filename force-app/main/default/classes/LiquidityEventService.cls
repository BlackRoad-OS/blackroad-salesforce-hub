/**
 * @description Service class for Liquidity Event calculations
 * Handles QSBS analysis, tax estimates, and net proceeds calculations
 * @author BlackRoad OS
 */
public with sharing class LiquidityEventService {

    // Tax rates (2024 federal rates - simplified)
    private static final Decimal LONG_TERM_CAP_GAINS_RATE = 0.20;
    private static final Decimal SHORT_TERM_RATE = 0.37;
    private static final Decimal NIIT_RATE = 0.038; // Net Investment Income Tax
    private static final Decimal STATE_TAX_ESTIMATE = 0.05; // Default state estimate
    private static final Decimal QSBS_EXCLUSION_LIMIT = 10000000; // $10M or 10x basis

    /**
     * @description Calculates estimated tax liability for a liquidity event
     * @param event The Liquidity_Event__c record
     * @return Estimated tax amount
     */
    public static Decimal calculateEstimatedTax(Liquidity_Event__c event) {
        if (event.Gross_Proceeds__c == null || event.Gross_Proceeds__c <= 0) {
            return 0;
        }

        Decimal grossProceeds = event.Gross_Proceeds__c;
        Decimal taxableAmount = grossProceeds;

        // QSBS Exclusion (Section 1202)
        if (event.QSBS_Eligible__c == 'Yes - Verified') {
            Decimal exclusion = Math.min(grossProceeds, QSBS_EXCLUSION_LIMIT);
            taxableAmount = grossProceeds - exclusion;
        }

        if (taxableAmount <= 0) {
            return 0;
        }

        // Calculate federal tax (assuming long-term gains)
        Decimal federalTax = taxableAmount * LONG_TERM_CAP_GAINS_RATE;

        // Add NIIT for high earners (simplified - assumes applies)
        Decimal niit = taxableAmount * NIIT_RATE;

        // Add state tax estimate
        Decimal stateTax = taxableAmount * STATE_TAX_ESTIMATE;

        return (federalTax + niit + stateTax).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * @description Calculates net proceeds after estimated taxes
     * @param event The Liquidity_Event__c record
     * @return Net proceeds amount
     */
    public static Decimal calculateNetProceeds(Liquidity_Event__c event) {
        if (event.Gross_Proceeds__c == null) {
            return 0;
        }

        Decimal estimatedTax = calculateEstimatedTax(event);
        return event.Gross_Proceeds__c - estimatedTax;
    }

    /**
     * @description Updates tax and net proceeds calculations on liquidity events
     * @param eventIds Set of Liquidity_Event__c IDs to update
     */
    public static void recalculateEvents(Set<Id> eventIds) {
        if (eventIds == null || eventIds.isEmpty()) {
            return;
        }

        List<Liquidity_Event__c> events = [
            SELECT Id, Gross_Proceeds__c, QSBS_Eligible__c
            FROM Liquidity_Event__c
            WHERE Id IN :eventIds
            WITH SECURITY_ENFORCED
        ];

        List<Liquidity_Event__c> eventsToUpdate = new List<Liquidity_Event__c>();

        for (Liquidity_Event__c evt : events) {
            Decimal estimatedTax = calculateEstimatedTax(evt);
            Decimal netProceeds = calculateNetProceeds(evt);

            eventsToUpdate.add(new Liquidity_Event__c(
                Id = evt.Id,
                Estimated_Tax__c = estimatedTax,
                Net_Proceeds__c = netProceeds
            ));
        }

        if (!eventsToUpdate.isEmpty()) {
            update eventsToUpdate;
        }
    }

    /**
     * @description Analyzes QSBS eligibility factors
     * @param grossProceeds The gross sale proceeds
     * @param costBasis Original cost basis (for 10x calculation)
     * @param holdingPeriodYears Years stock was held
     * @return Map with eligibility analysis
     */
    public static Map<String, Object> analyzeQSBSEligibility(
        Decimal grossProceeds,
        Decimal costBasis,
        Decimal holdingPeriodYears
    ) {
        Map<String, Object> analysis = new Map<String, Object>();

        // Check 5-year holding requirement
        Boolean meetsHoldingPeriod = holdingPeriodYears >= 5;
        analysis.put('meetsHoldingPeriod', meetsHoldingPeriod);
        analysis.put('holdingPeriodYears', holdingPeriodYears);

        // Calculate maximum exclusion (greater of $10M or 10x basis)
        Decimal maxExclusion = Math.max(QSBS_EXCLUSION_LIMIT, costBasis * 10);
        analysis.put('maxExclusion', maxExclusion);

        // Calculate excludable gain
        Decimal excludableGain = Math.min(grossProceeds - costBasis, maxExclusion);
        analysis.put('excludableGain', excludableGain);

        // Calculate tax savings
        Decimal taxSavings = excludableGain * (LONG_TERM_CAP_GAINS_RATE + NIIT_RATE);
        analysis.put('estimatedTaxSavings', taxSavings);

        // Overall eligibility
        analysis.put('isEligible', meetsHoldingPeriod && excludableGain > 0);

        return analysis;
    }

    /**
     * @description Gets pending liquidity events requiring attention
     * @return List of pending events
     */
    public static List<Liquidity_Event__c> getPendingEvents() {
        return [
            SELECT Id, Name, Event_Type__c, Gross_Proceeds__c,
                   Estimated_Tax__c, Net_Proceeds__c, QSBS_Eligible__c,
                   Status__c, Household__c, Household__r.Name
            FROM Liquidity_Event__c
            WHERE Status__c IN ('Pending', 'In Progress')
            WITH SECURITY_ENFORCED
            ORDER BY Gross_Proceeds__c DESC
        ];
    }
}
