import { LightningElement, track } from 'lwc';

const FEDERAL_RATE = 0.238; // 20% + 3.8% NIIT
const QSBS_EXCLUSION_LIMIT = 10000000;

const STATE_RATES = {
    'CA': 0.133,
    'NY': 0.109,
    'NJ': 0.1075,
    'TX': 0,
    'FL': 0,
    'WA': 0.07,
    'MA': 0.09,
    'IL': 0.0495,
    'PA': 0.0307,
    'Other': 0.05
};

export default class QsbsCalculator extends LightningElement {
    @track grossProceeds = 5000000;
    @track costBasis = 100000;
    @track holdingYears = 6;
    @track selectedState = 'CA';
    @track showResults = false;

    // Calculated values
    gain = 0;
    exclusion = 0;
    taxableGain = 0;
    taxWithout = 0;
    taxWith = 0;
    stateTaxWithout = 0;
    stateTaxWith = 0;
    savings = 0;
    isEligible = false;
    eligibilityReason = '';

    get stateOptions() {
        return Object.keys(STATE_RATES).map(state => ({
            label: state === 'Other' ? 'Other (5% estimate)' : state,
            value: state
        }));
    }

    get isValid() {
        return this.grossProceeds > 0 && this.costBasis >= 0 && this.holdingYears > 0;
    }

    get isInvalid() {
        return !this.isValid;
    }

    handleGrossProceedsChange(event) {
        this.grossProceeds = parseFloat(event.target.value) || 0;
        this.showResults = false;
    }

    handleCostBasisChange(event) {
        this.costBasis = parseFloat(event.target.value) || 0;
        this.showResults = false;
    }

    handleHoldingYearsChange(event) {
        this.holdingYears = parseFloat(event.target.value) || 0;
        this.showResults = false;
    }

    handleStateChange(event) {
        this.selectedState = event.detail.value;
        this.showResults = false;
    }

    calculateSavings() {
        // Calculate gain
        this.gain = this.grossProceeds - this.costBasis;

        // Check eligibility
        if (this.holdingYears < 5) {
            this.isEligible = false;
            this.eligibilityReason = 'Stock must be held for at least 5 years.';
            this.exclusion = 0;
        } else {
            this.isEligible = true;
            // Exclusion is greater of $10M or 10x basis
            const maxExclusion = Math.max(QSBS_EXCLUSION_LIMIT, this.costBasis * 10);
            this.exclusion = Math.min(this.gain, maxExclusion);
        }

        // Calculate taxable gain with QSBS
        this.taxableGain = Math.max(0, this.gain - this.exclusion);

        // Get state rate
        const stateRate = STATE_RATES[this.selectedState] || 0.05;

        // Federal tax calculations
        this.taxWithout = this.gain * FEDERAL_RATE;
        this.taxWith = this.taxableGain * FEDERAL_RATE;

        // State tax (some states conform to QSBS, some don't - simplified)
        // CA does NOT conform to QSBS
        const stateConforms = !['CA'].includes(this.selectedState);
        this.stateTaxWithout = this.gain * stateRate;
        this.stateTaxWith = stateConforms ? this.taxableGain * stateRate : this.gain * stateRate;

        // Total savings
        const totalWithout = this.taxWithout + this.stateTaxWithout;
        const totalWith = this.taxWith + this.stateTaxWith;
        this.savings = totalWithout - totalWith;

        this.showResults = true;
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
        }).format(value);
    }

    get formattedGain() { return this.formatCurrency(this.gain); }
    get formattedExclusion() { return this.formatCurrency(this.exclusion); }
    get formattedTaxableGain() { return this.formatCurrency(this.taxableGain); }
    get formattedTaxWithout() { return this.formatCurrency(this.taxWithout); }
    get formattedTaxWith() { return this.formatCurrency(this.taxWith); }
    get formattedStateTaxWithout() { return this.formatCurrency(this.stateTaxWithout); }
    get formattedStateTaxWith() { return this.formatCurrency(this.stateTaxWith); }
    get formattedTotalTaxWithout() { return this.formatCurrency(this.taxWithout + this.stateTaxWithout); }
    get formattedTotalTaxWith() { return this.formatCurrency(this.taxWith + this.stateTaxWith); }
    get formattedSavings() { return this.formatCurrency(this.savings); }
}
