# Manual Test Users

Rules for creating users in development (Rails console, demos, manual QA) — not for specs.

For spec user creation, see `../test-data-user.md` which uses a different password (`Sp3c$Password`) to keep spec credentials distinct from dev credentials.

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
