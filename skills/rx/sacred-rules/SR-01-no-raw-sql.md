# SR-01: No Raw SQL

**Level:** MUST follow
**Category:** Security & Maintainability

## Rule

Never use raw SQL strings (`execute`, `find_by_sql`, string interpolation in `where`). Use ActiveRecord query interface exclusively.

## Why

Raw SQL introduces SQL injection risk, bypasses ActiveRecord's type casting and sanitization, and makes queries database-dependent. RX handles sensitive pharmaceutical contract data — SQL injection is a critical security risk.

## Incorrect

```ruby
# BAD: Raw SQL with string interpolation
User.where("email = '#{params[:email]}'")

# BAD: find_by_sql
User.find_by_sql("SELECT * FROM users WHERE org_id = #{org_id}")

# BAD: execute
ActiveRecord::Base.connection.execute("UPDATE users SET active = true WHERE id = #{id}")
```

## Correct

```ruby
# GOOD: ActiveRecord query interface
User.where(email: params[:email])

# GOOD: Parameterized where
User.where("email = ?", params[:email])

# GOOD: Named bind
User.where("email = :email AND org_id = :org", email: params[:email], org: current_organization.id)

# GOOD: update via ActiveRecord
User.find(id).update(active: true)
```

## Exception

`safety_assured` blocks in migrations may use raw SQL when ActiveRecord doesn't support the operation. Document why.

## Validation

```bash
# Search for raw SQL patterns
grep -rn "find_by_sql\|\.execute(" app/
grep -rn 'where(".*#{' app/
```
