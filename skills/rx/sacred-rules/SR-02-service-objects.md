# SR-02: Business Logic in Services

**Level:** MUST follow
**Category:** Architecture

## Rule

Place all business logic in `app/services/`. Models handle data access and validations only. Controllers handle request/response only.

## Why

RX has 107+ models and 119+ controllers. Without this boundary, business logic scatters across the codebase, making it impossible to find, test, or reuse. Services are the single source of truth for "what the app does."

## Incorrect

```ruby
# BAD: Business logic in controller
class QuoteGroupsController < ApplicationController
  def accept_sow
    @quote_group.update(sow_accepted_at: Time.current)
    @quote_group.quotes.each { |q| q.update(status: 'accepted') }
    SalesforceSync.push(@quote_group)
    QuoteGroupMailer.sow_accepted(@quote_group).deliver_later
  end
end

# BAD: Business logic in model
class QuoteGroup < ApplicationRecord
  def accept_sow
    update(sow_accepted_at: Time.current)
    quotes.each { |q| q.update(status: 'accepted') }
    # Mixing persistence with side effects
  end
end
```

## Correct

```ruby
# GOOD: Service handles the business logic
# app/services/quote_group_acceptance_service.rb
class QuoteGroupAcceptanceService
  def self.accept(quote_group)
    new.accept(quote_group)
  end

  def accept(quote_group)
    quote_group.update(sow_accepted_at: Time.current)
    quote_group.quotes.each { |q| q.update(status: 'accepted') }
    SalesforceSync.push(quote_group)
    QuoteGroupMailer.sow_accepted(quote_group).deliver_later
  end
end

# Controller just delegates
class QuoteGroupsController < ApplicationController
  def accept_sow
    QuoteGroupAcceptanceService.accept(@quote_group)
    redirect_to @quote_group
  end
end
```

## RX Convention

Services use the `self.method` → `new.method` delegation pattern:

```ruby
class LegalNameService
  def self.assay_depot_legal_name_for(obj)
    new.assay_depot_legal_name_for(obj)
  end

  def assay_depot_legal_name_for(obj)
    # logic here
  end
end
```

## Validation

If a controller action has more than 5 lines of non-routing logic, it probably needs a service.
