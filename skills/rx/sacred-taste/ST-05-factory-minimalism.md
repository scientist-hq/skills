# ST-05: Minimal Factory Setup in Tests

**Level:** SHOULD follow
**Category:** Testing

## Preference

Generate only the models needed for each specific test. Avoid creating full object graphs when a simple `build` or `double` will do.

## Why

RX has 134+ FactoryBot factories. Full `create` calls hit the database and trigger callbacks, making tests slow. Most tests only need a subset of attributes.

## Patterns (fastest to slowest)

### 1. Test doubles (no DB, no factory)

```ruby
let(:unknown_object) do
  double('UnknownObject', submitted_at: 1.day.ago)
end
```

### 2. Stubs on real objects

```ruby
let(:quote_group) { FactoryBot.create(:pg_quote_group) }

before do
  allow(quote_group)
    .to receive(:first_proposal_submitted_date)
    .and_return(1.day.ago)
end
```

### 3. FactoryBot.build (no DB hit)

```ruby
let(:user) { FactoryBot.build(:pg_user, email: "test@example.com") }
```

### 4. FactoryBot.create (only when DB required)

```ruby
# Only create when you need associations or DB queries
let(:quote_group) do
  FactoryBot.create(:pg_quote_group, remittance_address: remittance_address)
end
```

## Rule of Thumb

Use `double` > `build` > `create`. Only escalate when the test genuinely requires it.
