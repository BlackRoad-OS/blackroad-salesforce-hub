/**
 * @description Service class for Client Household business logic
 * Handles AUM calculations, fee computations, and review scheduling
 * @author BlackRoad OS
 */
public with sharing class HouseholdService {

    // Fee tiers based on AUM (basis points)
    private static final Map<Decimal, Decimal> FEE_TIERS = new Map<Decimal, Decimal>{
        0 => 100,           // 1.00% for $0-500K
        500000 => 85,       // 0.85% for $500K-1M
        1000000 => 75,      // 0.75% for $1M-3M
        3000000 => 60,      // 0.60% for $3M-10M
        10000000 => 50      // 0.50% for $10M+
    };

    /**
     * @description Calculates total AUM for a household from all linked financial accounts
     * @param householdId The Id of the Client_Household__c record
     * @return Total AUM value
     */
    public static Decimal calculateTotalAUM(Id householdId) {
        Decimal totalAUM = 0;

        List<Financial_Account__c> accounts = [
            SELECT Current_Value__c
            FROM Financial_Account__c
            WHERE Household__c = :householdId
            WITH SECURITY_ENFORCED
        ];

        for (Financial_Account__c acct : accounts) {
            if (acct.Current_Value__c != null) {
                totalAUM += acct.Current_Value__c;
            }
        }

        return totalAUM;
    }

    /**
     * @description Calculates annual advisory fee based on tiered AUM schedule
     * @param totalAUM The total assets under management
     * @return Annual fee amount
     */
    public static Decimal calculateAnnualFee(Decimal totalAUM) {
        if (totalAUM == null || totalAUM <= 0) {
            return 0;
        }

        Decimal basisPoints = 100; // Default 1%

        // Find applicable tier
        List<Decimal> tiers = new List<Decimal>(FEE_TIERS.keySet());
        tiers.sort();

        for (Integer i = tiers.size() - 1; i >= 0; i--) {
            if (totalAUM >= tiers[i]) {
                basisPoints = FEE_TIERS.get(tiers[i]);
                break;
            }
        }

        return (totalAUM * basisPoints / 10000).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * @description Updates household AUM and fee based on linked accounts
     * @param householdIds Set of household IDs to update
     */
    public static void recalculateHouseholds(Set<Id> householdIds) {
        if (householdIds == null || householdIds.isEmpty()) {
            return;
        }

        List<Client_Household__c> householdsToUpdate = new List<Client_Household__c>();

        // Aggregate account values by household
        Map<Id, Decimal> householdAUM = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Household__c, SUM(Current_Value__c) totalValue
            FROM Financial_Account__c
            WHERE Household__c IN :householdIds
            WITH SECURITY_ENFORCED
            GROUP BY Household__c
        ]) {
            householdAUM.put((Id)ar.get('Household__c'), (Decimal)ar.get('totalValue'));
        }

        // Update each household
        for (Id hhId : householdIds) {
            Decimal aum = householdAUM.containsKey(hhId) ? householdAUM.get(hhId) : 0;
            Decimal fee = calculateAnnualFee(aum);

            householdsToUpdate.add(new Client_Household__c(
                Id = hhId,
                Total_AUM__c = aum,
                Annual_Fee__c = fee
            ));
        }

        if (!householdsToUpdate.isEmpty()) {
            update householdsToUpdate;
        }
    }

    /**
     * @description Schedules next review date based on risk tolerance and AUM
     * @param household The household record
     * @return Next review date
     */
    public static Date calculateNextReviewDate(Client_Household__c household) {
        Integer monthsUntilReview = 12; // Default annual

        // High-net-worth clients get more frequent reviews
        if (household.Total_AUM__c != null && household.Total_AUM__c >= 5000000) {
            monthsUntilReview = 6; // Semi-annual for $5M+
        }

        // Aggressive risk profiles need more frequent monitoring
        if (household.Risk_Tolerance__c == 'Aggressive' ||
            household.Risk_Tolerance__c == 'Moderately Aggressive') {
            monthsUntilReview = Math.min(monthsUntilReview, 6);
        }

        // Special situations require quarterly reviews
        if (household.Household_Status__c == 'Deceased Primary' ||
            household.Household_Status__c == 'In Transition') {
            monthsUntilReview = 3;
        }

        return Date.today().addMonths(monthsUntilReview);
    }

    /**
     * @description Gets households requiring review within specified days
     * @param daysAhead Number of days to look ahead
     * @return List of households needing review
     */
    public static List<Client_Household__c> getHouseholdsNeedingReview(Integer daysAhead) {
        Date cutoffDate = Date.today().addDays(daysAhead);

        return [
            SELECT Id, Name, Total_AUM__c, Risk_Tolerance__c,
                   Last_Review_Date__c, Next_Review_Date__c,
                   Primary_Contact__c, Secondary_Contact__c
            FROM Client_Household__c
            WHERE Next_Review_Date__c <= :cutoffDate
            AND Household_Status__c = 'Active'
            WITH SECURITY_ENFORCED
            ORDER BY Next_Review_Date__c ASC
        ];
    }
}
