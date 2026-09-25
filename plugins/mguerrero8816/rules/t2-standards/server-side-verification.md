# Server-Side Verification

## Read Related Records Through the Association, Not From Params

If the loaded record can reach a fact through an association, read the fact from there. Use a param only for a fact that the server cannot know: a value the user typed, or a choice the server cannot narrow. This applies to all code, not only to security checks.

- ❌ BAD: `provider_id: params[:provider_id]` when the controller already loaded `@quoted_ware`
- ✅ GOOD: `provider: @quoted_ware.provider, organization: @quoted_ware.organization.canonical_organization`
- ❌ BAD: `Pg::Proposal::AMENDMENT_TYPES.include?(proposal_param('proposal_type'))`
- ✅ GOOD: `quoted_ware.provider_purchase_orders.active.includes(:proposal).any? { |po| po.proposal&.purchasable_type? }`

## Scope Every Id Lookup to the Loaded Record

When the client must name a related record, start the lookup from the loaded record's association. Never start it from the class.

- ❌ BAD: `Pg::ProviderPurchaseOrder.active.find_by_uuid(params[:purchase_order_id])`
- ✅ GOOD: `@quoted_ware.provider_purchase_orders.active.find_by_uuid(params[:purchase_order_id])`

## A Check That Removes a Restriction Must Come From the Server

This matters most when a value decides that a restriction does not apply. Examples are an exemption from a lock or a read-only state, a skipped validation, and the record that a rule is measured against. A param that adds a restriction is low risk. A param that removes one gives the decision to the person that the restriction controls.

## No Excuses for Param Trust

- Do not trust a param in a new place because another place already permits it. Derive the fact from the record. Report the old permitted param as a separate defect.
- Do not accept a param check because a later validation "would catch" a forged value. Write a spec that posts the forged value, run it, and read the result. A validation that reads the same param does not catch the forgery.

## Report the Pre-Existing Half Separately

Fix the part of a param-trust defect that the current change added. Report the old part as a separate finding with its own fix.
