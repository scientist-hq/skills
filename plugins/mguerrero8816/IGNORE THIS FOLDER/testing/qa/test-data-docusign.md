---
description: How to create mock DocuSign envelope and signer records in local development for manual QA, specifically to test the SOW purchase flow gating.
---

## What This Sets Up

The SOW purchase form gates on `envelope.active?` and `@docusign_customer_signers.present?`. To test this in dev without a real DocuSign integration, you need:

1. A proposal with `docusign_signature_required: true`
2. At least one `Pg::DocusignCustomerSigner` on the proposal
3. A `Pg::DocusignEnvelope` on the proposal with the desired `envelope_status`

## Finding a Suitable Proposal

You need a proposal that is `purchasable?`, `selectable?`, and in a quote group that `could?(:accept_sow)`. Find one in the AZ org:

```ruby
az = Pg::Organization.find_by(subdomain: 'az')
qg = Pg::QuoteGroup.joins(:org).where(organizations: { id: az.id })
       .detect { |q| q.could?(:accept_sow) }
p  = qg.proposals.detect { |pr| pr.purchasable? && pr.selectable? }
puts "QG uuid: #{qg.uuid}"
puts "Proposal id: #{p.id}, uuid: #{p.uuid}"
```

## Step 1 — Enable DocuSign on the Proposal

```ruby
p.update!(docusign_signature_required: true)
```

## Step 2 — Create a Customer Signer

```ruby
Pg::DocusignCustomerSigner.create!(
  signable_type: 'Pg::ProposalBase',
  signable_id:   p.id,
  signer_status: 'completed',   # or 'declined', 'pending', etc.
  name:          'Test Customer',
  email:         'test@az.test',
  type:          'Pg::DocusignCustomerSigner',
  dynamic_signer: false
)
```

## Step 3 — Create an Envelope

```ruby
Pg::DocusignEnvelope.create!(
  docusignable_type: 'Pg::ProposalBase',
  docusignable_id:   p.id,
  envelope_status:   'completed',   # see status reference below
  envelope_id:       'test-' + SecureRandom.hex(6)
)
```

Verify the fix works as expected:
```ruby
e = Pg::DocusignEnvelope.last
puts e.active?    # true for 'completed' after the PR #36933 fix
                  # false for 'declined', 'voided', 'deleted', 'timedout'
```

## Envelope Status Reference

| `envelope_status` | `active?` | Notes |
|---|---|---|
| `completed` | `true` | Fully signed — purchase form should render |
| `sent` | `true` | Awaiting signatures |
| `delivered` | `true` | Viewed but not signed |
| `declined` | `false` | Terminal — shows declined error in purchase form |
| `voided` | `false` | Terminal |
| `deleted` | `false` | Terminal |
| `timedout` | `false` | Terminal |

`TERMINAL_STATUSES` is defined on `Pg::DocusignEnvelope` — check it if statuses change.

## Purchase Form URL

Once data is set up, navigate directly to the purchase form partial (unstyled but useful for quick verification):

```
https://az.test/quote_groups/{qg_uuid}/proposals/{proposal_uuid}/purchase_form
```

Or go through the proper UI flow — see `skills/playwright/accept-sow.md`.

## Teardown

To reset the proposal back to a non-DocuSign state after testing:

```ruby
p.update!(docusign_signature_required: false)
Pg::DocusignSigner.where(signable: p).destroy_all
Pg::DocusignEnvelope.where(docusignable: p).destroy_all
```
