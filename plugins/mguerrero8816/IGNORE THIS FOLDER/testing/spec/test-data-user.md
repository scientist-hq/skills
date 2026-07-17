---
description: Minimal pattern for creating a Pg::User in specs with the correct spec-only password and required Devise fields.
---

# Test Data — User

```ruby
let!(:user) do
  Pg::User.create!(
    first_name: 'Test',
    last_name: 'User',
    email: "test-#{SecureRandom.hex(4)}@example.com",
    password: 'Sp3c$Password',
    password_confirmation: 'Sp3c$Password',
    privacy_policy: true,
    confirmed_at: Time.now
  )
end
```

- `confirmed_at` is required to suppress Devise's confirmation email in tests
- `activated_at`, `tos_signed_at`, and `user_agreement_signed_at` are NOT required — omit them
- Always use `Sp3c$Password` (not `!Testing1234`) so spec credentials are distinct from dev credentials
- If specs start failing due to user creation, update the minimum fields here
