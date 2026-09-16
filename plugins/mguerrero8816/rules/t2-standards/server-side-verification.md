# Server-Side Verification

## Resolve a Related Record Through the Association, Never From Params

**When the record in hand can already reach a fact through an association, read it from there. Do not read it from an incoming param.**

This is the default for all code, not only for security checks. A param is for a fact the server cannot already know — a value the user just typed, or a choice among records the server cannot narrow. Everything the object graph already answers must come from the object graph.

Ask "can the record I loaded already tell me this?" before you reach for `params`. If the answer is yes, the param is a second, weaker copy of a fact the server holds. It can disagree with the real one, and it puts the client in charge of a value the client does not own.

**Examples:**
- ❌ BAD: `provider_id: params[:provider_id]` when the controller already loaded `@quoted_ware`
- ✅ GOOD: `provider: @quoted_ware.provider, organization: @quoted_ware.organization.canonical_organization` — the pattern `add_milestone_params` already uses
- ❌ BAD: `Pg::Proposal::AMENDMENT_TYPES.include?(proposal_param('proposal_type'))` — the request's own purchase orders answer this
- ✅ GOOD: `quoted_ware.provider_purchase_orders.active.includes(:proposal).any? { |po| po.proposal&.purchasable_type? }`

## Scope Every Id Lookup to the Record in Hand

Sometimes the client must name which related record it means. Then the param carries an id, and the lookup starts from the loaded record's association — never from the class.

A global `find_by_uuid` reaches every row in the table. An association-scoped lookup can only return a record that belongs where it should.

**Examples:**
- ❌ BAD: `Pg::ProviderPurchaseOrder.active.find_by_uuid(params[:purchase_order_id])`
- ✅ GOOD: `@quoted_ware.provider_purchase_orders.active.find_by_uuid(params[:purchase_order_id])`
- ✅ GOOD: `Pg::ProposalTemplate.where(provider: @quoted_ware.provider).find_by_uuid(params[:proposal_template_id])`

## A Check That Relaxes a Restriction Must Be Server-Derived

The rule above matters most where a value decides that a restriction does **not** apply:

- an exemption from a lock, a freeze, or a read-only state
- a branch that skips a validation
- a flag that decides which record a rule is measured against

A param that *adds* a restriction is low risk. A param that *removes* one hands the decision to the person the restriction exists to constrain.

## Existing Trust Elsewhere Is Not a Licence

**Never reason "this param is already permitted at create, so reading it here is safe."** A param trusted in one place is not therefore safe in a new place. Spreading it widens the reach of the original weakness.

- ❌ BAD: "`:proposal_type` is in the permit list already, so the endpoint can read it too"
- ✅ GOOD: derive the same fact from the loaded record, and report the existing permitted param as a separate defect

## Never Justify Param Trust With an Unverified Backstop

**Do not accept a param-based check because a later validation "would catch" a forged value. Run the case first and confirm the validation fires.**

A backstop that reads the same forged param does not fire. That is the common shape: an endpoint trusts `proposal_type`, and the validator it relies on also branches on `proposal_type`, so one lie disables both.

Write the failing case, run it, and read the result. Do not reason about it from the source.

- ❌ BAD: "if they lie about the type, `validate_locked_structure` refuses the structure at submit"
- ✅ GOOD: run a spec that posts the forged type, and confirm the error appears — or find that it does not, and fix the check

## Report the Pre-Existing Half Separately

A param-trust defect usually has two halves: the old trusted read, and the new code that widened it. Fix the half the current change introduced. Report the pre-existing half as its own finding with its own fix, rather than folding it in or calling it settled.
