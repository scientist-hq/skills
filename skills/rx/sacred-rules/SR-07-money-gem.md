# SR-07: Money Gem for All Monetary Values

**Level:** MUST follow
**Category:** Data Integrity

## Rule

All monetary values must use the `Money` gem. Store amounts as integer cents in the database. Use `Money` objects in Ruby for arithmetic and display.

## Why

Floating-point arithmetic causes rounding errors in financial calculations. RX handles purchase orders, invoices, and contracts for pharmaceutical companies — a penny rounding error on a million-dollar contract is unacceptable.

## RX Money Pattern

RX does NOT use the `monetize` macro. Instead it uses explicit `Money.from_cents` and `Money.from_amount`:

```ruby
# Converting stored cents to Money object
def get_price(price)
  if price.to_s.match?(/^\d+$/)
    Money.from_cents(price, currency)
  else
    Money.from_amount(::NumberHelper.price_as_number(price), currency)
  end
end

# Converting any input to cents for DB storage
def set_price(price)
  case price
  when Money
    price.cents
  when String
    (::NumberHelper.price_as_number(price) * 100).round(0).to_i
  when BigDecimal
    (price * 100).round(0).to_i
  else
    price.to_i
  end
end
```

## Common Operations

```ruby
# Create from cents (DB value)
amount = Money.from_cents(10000, "USD")  # $100.00

# Create from decimal
amount = Money.from_amount(100.00, "USD")

# Display
amount.format  # "$100.00"

# Currency metadata
Money::Currency.find("USD")&.decimal_places  # 2

# Persist to DB
column_value = amount.cents  # 10000
```

## Incorrect

```ruby
# BAD: Float arithmetic
total = price * quantity  # Float rounding errors

# BAD: Storing as decimal without Money
update(amount: 99.99)  # Loses currency context
```
