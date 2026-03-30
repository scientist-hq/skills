# PT-02: Presenter Pattern

## Template

```ruby
# app/presenters/feature_presenter.rb
class FeaturePresenter
  attr_accessor :object, :organization, :options

  def initialize(object, organization, **options)
    self.object       = object
    self.organization = organization
    self.options      = options
  end

  def display_name
    # Computed display value
  end

  def visible?
    # Boolean for view conditional
  end

  def formatted_amount
    # Formatting logic
    Money.from_cents(object.amount_cents, object.currency).format
  end
end
```

## RX Reference Implementation

`app/presenters/address_form_presenter.rb` — demonstrates:
- `attr_accessor` for all instance data
- `**options` keyword splat
- `alias_method :method?, :method` for boolean aliases
- Query methods that scope to organization
- No base class (plain Ruby)

## Conventions

- Place in `app/presenters/` (use subdirectories for feature groups)
- Instantiate in the controller, pass to the view
- Keep methods focused on presentation (formatting, visibility, labels)
- Presenters can call other presenters or services
- Use `attr_accessor` not `attr_reader` (RX convention)

## Controller Usage

```ruby
def show
  @presenter = FeaturePresenter.new(@record, current_organization)
end
```

## View Usage (HAML)

```haml
- if @presenter.visible?
  %h1= @presenter.display_name
  %span.amount= @presenter.formatted_amount
```
