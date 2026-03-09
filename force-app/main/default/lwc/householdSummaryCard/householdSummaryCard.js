import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Client_Household__c.Name';
import TOTAL_AUM_FIELD from '@salesforce/schema/Client_Household__c.Total_AUM__c';
import ANNUAL_FEE_FIELD from '@salesforce/schema/Client_Household__c.Annual_Fee__c';
import STATUS_FIELD from '@salesforce/schema/Client_Household__c.Household_Status__c';
import RISK_FIELD from '@salesforce/schema/Client_Household__c.Risk_Tolerance__c';
import NEXT_REVIEW_FIELD from '@salesforce/schema/Client_Household__c.Next_Review_Date__c';
import LAST_REVIEW_FIELD from '@salesforce/schema/Client_Household__c.Last_Review_Date__c';

const FIELDS = [
    NAME_FIELD,
    TOTAL_AUM_FIELD,
    ANNUAL_FEE_FIELD,
    STATUS_FIELD,
    RISK_FIELD,
    NEXT_REVIEW_FIELD,
    LAST_REVIEW_FIELD
];

export default class HouseholdSummaryCard extends LightningElement {
    @api recordId;
    isLoading = true;
    household;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredHousehold({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.household = {
                Name: getFieldValue(data, NAME_FIELD),
                Total_AUM__c: getFieldValue(data, TOTAL_AUM_FIELD),
                Annual_Fee__c: getFieldValue(data, ANNUAL_FEE_FIELD),
                Household_Status__c: getFieldValue(data, STATUS_FIELD),
                Risk_Tolerance__c: getFieldValue(data, RISK_FIELD),
                Next_Review_Date__c: getFieldValue(data, NEXT_REVIEW_FIELD),
                Last_Review_Date__c: getFieldValue(data, LAST_REVIEW_FIELD)
            };
        } else if (error) {
            console.error('Error loading household:', error);
        }
    }

    get formattedAUM() {
        if (!this.household?.Total_AUM__c) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
        }).format(this.household.Total_AUM__c);
    }

    get formattedFee() {
        if (!this.household?.Annual_Fee__c) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
        }).format(this.household.Annual_Fee__c);
    }

    get formattedReviewDate() {
        if (!this.household?.Next_Review_Date__c) return 'Not scheduled';
        return new Date(this.household.Next_Review_Date__c).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    get reviewOverdue() {
        if (!this.household?.Next_Review_Date__c) return false;
        return new Date(this.household.Next_Review_Date__c) < new Date();
    }

    get statusClass() {
        const status = this.household?.Household_Status__c;
        if (status === 'Active') return 'slds-badge_success';
        if (status === 'Deceased Primary') return 'slds-badge_warning';
        if (status === 'Prospect') return 'slds-badge_inverse';
        return '';
    }

    get reviewDateClass() {
        return this.reviewOverdue ? 'metric-value text-danger' : 'metric-value';
    }
}
