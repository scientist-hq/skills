# PT-03: RSpec Test Pattern

## Template

```ruby
require 'spec_helper'

describe ClassName do
  describe '#method_name' do
    let(:service) { described_class.new }

    context 'with valid input' do
      let(:input) { FactoryBot.create(:factory_name, attribute: value) }

      it 'produces expected result' do
        expect(service.method_name(input)).to eq(expected_value)
      end
    end

    context 'with edge case' do
      let(:input) { double('Input', attribute: edge_value) }

      it 'handles gracefully' do
        expect { service.method_name(input) }.to_not raise_error
      end
    end
  end
end
```

## RX Conventions

### File header
```ruby
require 'spec_helper'  # NOT rails_helper
```

### Organization
- `describe ClassName` at top level
- `describe '#instance_method'` or `describe '.class_method'`
- `context 'with condition'` for grouping scenarios
- `let` for lazy-loaded fixtures
- `before` for setup that mutates state

### Test data (see ST-05 for priority order)
```ruby
# Doubles — fastest, no DB
let(:obj) { double('Obj', name: 'test') }

# Stubs — override specific methods
before { allow(obj).to receive(:method).and_return(value) }

# FactoryBot.build — no DB hit
let(:user) { FactoryBot.build(:pg_user) }

# FactoryBot.create — DB required
let(:quote_group) { FactoryBot.create(:pg_quote_group) }
```

### Expectations
```ruby
expect(result).to eq(value)
expect(result).to be_truthy
expect(result).to include(item)
expect { action }.to raise_error(ErrorClass)
expect { action }.to change(Model, :count).by(1)
expect { action }.to_not raise_error
```

### Running Tests
```bash
# Single file
bundle exec rspec spec/services/feature_service_spec.rb

# Single example (by line number)
bundle exec rspec spec/services/feature_service_spec.rb:42

# Full suite (parallel)
bundle exec parallel_rspec
```

## RX Reference Implementation

`spec/services/legal_name_service_spec.rb` — demonstrates nested contexts, `let`, `allow/receive/and_return`, `double`, and `FactoryBot.create`.
