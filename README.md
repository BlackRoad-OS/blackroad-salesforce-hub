# BlackRoad OS Hub

**Meta-CRM Platform** - A CRM that manages CRMs.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    BLACKROAD OS HUB                             │
│                (Salesforce - Master Control)                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Connected   │  │ Connected   │  │ Connected   │             │
│  │ CRM #1      │  │ CRM #2      │  │ CRM #3      │             │
│  │ (FA CRM)    │  │ (Agency)    │  │ (Client X)  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              UNIFIED DATA LAYER                          │   │
│  │   • Cross-CRM Search    • Sync Status                   │   │
│  │   • Audit Logs          • Health Monitoring             │   │
│  │   • Template Library    • Workflow Engine               │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Custom Objects

### Hub Layer
| Object | Description |
|--------|-------------|
| `Connected_CRM__c` | Connected CRM instances managed by the hub |
| `CRM_Product__c` | CRM product templates (Financial Advisor CRM, etc.) |

### Financial Advisor CRM
| Object | Description |
|--------|-------------|
| `Client_Household__c` | Unified household view |
| `Financial_Account__c` | Individual financial accounts (IRA, brokerage, etc.) |
| `Distribution_Request__c` | Distribution/withdrawal workflows |
| `Mortality_Event__c` | Death/estate processing |
| `Liquidity_Event__c` | Business sales, large transfers |
| `Compliance_Log__c` | FINRA-compliant audit trail |

## Apex Classes

| Class | Description |
|-------|-------------|
| `BlackRoadHubController` | Hub dashboard controller |
| `FinancialAdvisorService` | FA CRM business logic |

## Lightning Components

| Component | Description |
|-----------|-------------|
| `blackroadHubDashboard` | Main hub command center |

## Deployment

```bash
# Authenticate to your org
sf org login web --alias blackroad-hub

# Deploy
sf project deploy start --target-org blackroad-hub

# Assign permission set
sf org assign permset --name BlackRoad_Hub_Admin --target-org blackroad-hub
```

## Target Org

- **Org:** securianfinancial-4e-dev-ed
- **URL:** https://securianfinancial-4e-dev-ed.develop.my.salesforce.com

## OAuth Credentials

Stored in Cloudflare Worker secrets:
- `SALESFORCE_CONSUMER_KEY`
- `SALESFORCE_CONSUMER_SECRET`

---

**BlackRoad OS** | Building compliance-first automation for regulated industries
