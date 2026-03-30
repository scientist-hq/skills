# SR-06: Authorization Checks on Every Controller Action

**Level:** MUST follow
**Category:** Security

## Rule

Every controller action must have authorization checks via `before_action`. No action should be accessible without verifying the user has permission.

## Why

RX is a multi-tenant platform serving pharmaceutical companies. Data leakage between organizations is a critical security and compliance risk.

## RX Authorization Pattern

RX uses Devise for authentication and custom `before_action` methods for authorization (not Pundit/CanCanCan):

```ruby
class QuoteGroupsController < ApplicationController
  before_action :authenticate_user!                              # Devise: must be logged in
  before_action :ensure_admin, only: %i[send_to_salesforce]      # Admin-only actions
  before_action :load_quote_group, only: %i[show accept_sow]     # Load + implicit ownership check
  before_action :can_edit_quote_group?, only: %i[accept_sow]     # Explicit permission check

  private

  def can_edit_quote_group?
    return true if helpers.can_edit_quote_group?(@quote_group, current_user, current_organization)
    redirect_to root_path, alert: t(:unauthorized)
  end
end
```

## Key Methods (from ApplicationController)

- `authenticate_user!` — Devise method, ensures user is logged in
- `ensure_admin` — checks `current_user.is_admin?(current_organization)`
- Custom `can_*?` methods — check specific permissions, redirect with `t(:unauthorized)` on failure

## Checklist for New Controllers

1. Add `before_action :authenticate_user!` (unless public endpoint)
2. Add resource-loading `before_action` that scopes to `current_organization`
3. Add permission-checking `before_action` for write operations
4. Verify the rejection response is `redirect_to root_path, alert: t(:unauthorized)`

## Validation

```bash
# Brakeman security scan
bundle exec brakeman --only-files app/controllers/your_controller.rb
```
