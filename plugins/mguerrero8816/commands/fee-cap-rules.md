# Fee Cap Rules

Rules specific to how commission fee caps work in RX.

## Nil Cap Semantics

**A nil `commission_fee_cap` means no cap was configured — treat it as infinite positive (∞)**

- A nil cap does NOT mean "no restriction" — it means the fee was uncapped
- Any finite `manual_fee_cap_amount` set on an amendment is less than ∞ and is therefore invalid
- Only `manual_fee_cap_amount: nil` (no override) is valid when the historical cap is nil
