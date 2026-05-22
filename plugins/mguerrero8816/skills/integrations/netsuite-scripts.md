---
description: Reference guide for developing and modifying NetSuite SuiteScript 2.1 files in /Users/mike/netsuite_scripts/, covering module patterns, record types, custom fields, and known gotchas.
---

# NetSuite SuiteScript Development

You are working on the NetSuite SuiteScript files for Scientist.com, located at `/Users/mike/netsuite_scripts/`.

## Folder Overview

All scripts use **SuiteScript 2.1** (`@NApiVersion 2.1`) and follow the AMD `define([...], function(...) { ... })` module pattern.

### Key Files

| File | Type | Purpose |
|------|------|---------|
| `restlet_dynamic.js` | RESTlet | Main CRUD handler — salesorder, purchaseorder, customer, vendor, vendorbill, vendorcredit, noninventoryitem |
| `restlet_standard.js` | RESTlet | Standard restlet variant |
| `restlet.js` | RESTlet | Original restlet (legacy) |
| `billInvoiceMapReduceScript.js` | Map/Reduce | Creates customer invoices from vendor bills |
| `billInvoiceSuitelet.js` | Suitelet | Invoice management UI |
| `salesorder_scheduled_script.js` | Scheduled Script | Sales order processing |
| `salesorder_suitelet.js` | Suitelet | Sales order UI |
| `SCF_Kyriba_scheduled_script.js` | Scheduled Script | Kyriba banking integration |
| `synaptic_scheduled_script.js` | Scheduled Script | Synaptic integration |
| `invoice_pdf.html.js` | PDF Template | Customer invoice PDF layout |
| `rev_rec-*.js` | Map/Reduce | Revenue recognition journal entries |
| `AVA_*.js` | Library | Avalara tax integration libraries |
| `AD_ava_suitelet.js` | Suitelet | Avalara suitelet |
| `taxbasis-map_reduce_script.js` | Map/Reduce | Tax basis calculations |
| `suitescript_snippets.js` | Snippets | Reusable utility patterns |
| `bill_status_sync/` | Directory | Bill status sync scripts |

## SuiteScript 2.1 Patterns Used Here

### Module Structure
```javascript
/**
 * @NApiVersion 2.1
 * @NScriptType Restlet  // or MapReduceScript, Suitelet, ScheduledScript, UserEventScript
 */
define(['N/record', 'N/search', 'N/log', 'N/error', 'N/task'],
  function(record, search, log, error, task) {
    // ...
    return { get, post, put, delete: _delete };
  }
);
```

### Common NetSuite Modules
- `N/record` — load, create, transform, save, delete records
- `N/search` — saved and ad-hoc searches
- `N/log` — `log.audit()`, `log.debug()`, `log.error()`
- `N/error` — `error.create({ name, message })`
- `N/task` — schedule map/reduce tasks

### Record Types in Use
- `salesorder` / `purchaseorder` — CPO/PPO
- `vendorbill` / `vendorcredit` — provider invoices/credits
- `customer` / `vendor` — legal entities
- `noninventoryitem` — wares/services
- `invoice` — customer invoices (deprecated path)

### Custom Fields Convention
- `custbody_rsm_scientist_internal_id` — internal RX record ID
- `custcolscientist_line_number` — milestone line number
- `custbody_rsm_po_reference` / `custbody_rsm_so_reference` — cross-references
- `custcol_milestone_title` — milestone title (must be non-nil, sliced to 998 chars)

## Known Gotchas

- **String slice limits**: NetSuite fields have character limits — always `.slice(0, N)` on strings before setting. Common limits: `memo` → 998, `tranid` → 45, `attention` → 149, `custcol_milestone_title` → 998.
- **Dynamic mode required** for sublists — always `isDynamic: true` when loading records you'll modify sublists on.
- **Tax nexus**: Must be set before tax lines. Use `taxregoverride: true` to override automatic tax.
- **Avalara vs. legacy tax**: `use_avalara_taxation` flag controls which path runs — Avalara returns early after nexus is set; legacy manually sets `taxdetails` sublist lines.
- **Shipping line matching**: Match by `custcol_shipping_item` boolean + `custcol_line_vendor` ID, not just description.
- **Subsidiary**: Set via search on `legalname`, not hardcoded ID. Always set on new records only.
- **`record.transform`**: Used for vendorbill (from PO) and vendorcredit (from vendorbill) — don't `record.load` these.
- **`executeMacro({id:'calculateTax'})`**: Required to refresh tax lines before manual override.

## Workflow

1. **Read the relevant file(s)** in `/Users/mike/netsuite_scripts/` first
2. **Understand context** — which record type, which script type, what the script does
3. **Make changes** following the SuiteScript 2.1 patterns already in use
4. **Note deployment**: These files are deployed manually to NetSuite — changes here don't auto-deploy. Remind the user to upload the updated script to NetSuite after editing.

## Getting Started

$ARGUMENTS

If no specific task is given, list the files in `/Users/mike/netsuite_scripts/` and ask what needs to be done.
