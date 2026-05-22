---
name: fee-cap-rules
description: Rules for how commission fee caps work in RX, including nil cap semantics and amendment validation.
---

# Fee Cap Rules

## Nil Cap Semantics

**A nil `commission_fee_cap` means no cap was configured — treat it as infinite positive (∞)**

- A nil cap does NOT mean "no restriction" — it means the fee was uncapped
- Any finite `manual_fee_cap_amount` set on an amendment is less than ∞ and is therefore invalid
- Only `manual_fee_cap_amount: nil` (no override) is valid when the historical cap is nil
