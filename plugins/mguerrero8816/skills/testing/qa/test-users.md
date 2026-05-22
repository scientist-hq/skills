---
name: test-users
description: Rules for creating test users in development and manual QA, including the standard password and distinction from spec credentials.
---

# Manual Test Users

For spec user creation, see `skills/testing/spec/test-data-user.md` which uses a different password (`Sp3c$Password`) to keep spec credentials distinct from dev credentials.

## Password

**ALWAYS use `!Testing1234` when creating test users manually.**

- Meets all security requirements (length, upper, lower, digits, special characters)
- Consistent password makes manual testing easier

```ruby
user = Pg::User.create!(
  email: 'test@example.com',
  password: '!Testing1234',
  password_confirmation: '!Testing1234'
)
```
