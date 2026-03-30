# PT-01: Service Object Pattern

## Template

```ruby
# app/services/feature_name_service.rb
class FeatureNameService
  # Class-level convenience method delegates to instance
  def self.perform(arg)
    new.perform(arg)
  end

  def perform(arg)
    validate(arg)
    execute(arg)
  end

  private

  def validate(arg)
    raise ArgumentError, "description" unless arg.valid_condition?
  end

  def execute(arg)
    # Business logic here
  end
end
```

## RX Reference Implementation

`app/services/legal_name_service.rb` — clean example of:
- `self.method` → `new.method` delegation
- Constants for business rules
- `case`/`when` for polymorphic dispatch
- Private helper methods

## Conventions

- One public method per service (or a small cohesive set)
- Name the class after what it does: `AcceptanceService`, `SyncService`, `CalculationService`
- Place in `app/services/` (use subdirectories for feature groups: `services/netsuite/`, `services/salesforce/`)
- No inheritance unless sharing significant behavior
- Return values over side effects where possible

## Testing

```ruby
# spec/services/feature_name_service_spec.rb
require 'spec_helper'

describe FeatureNameService do
  describe '#perform' do
    let(:service) { described_class.new }

    context 'with valid input' do
      it 'does the expected thing' do
        result = service.perform(valid_arg)
        expect(result).to eq(expected)
      end
    end

    context 'with invalid input' do
      it 'raises an error' do
        expect { service.perform(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
```
