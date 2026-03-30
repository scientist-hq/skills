# PT-06: External Service Integration Pattern

## Service Structure

```ruby
# app/services/external_name/sync_service.rb
class ExternalName::SyncService
  def self.perform(record)
    new.perform(record)
  end

  def perform(record)
    payload = build_payload(record)
    response = send_request(payload)
    handle_response(response, record)
  end

  private

  def build_payload(record)
    # Transform RX data to external format
  end

  def send_request(payload)
    # HTTP call to external service
  end

  def handle_response(response, record)
    # Process response, update record
  end
end
```

## Testing with VCR

```ruby
# spec/services/external_name/sync_service_spec.rb
require 'spec_helper'

describe ExternalName::SyncService do
  subject(:service) { described_class.new }

  let(:record) do
    FactoryBot.create(:record, relevant_attributes: values)
  end

  it "sends data to external service" do
    expect {
      VCR.use_cassette('external_name_sync') do
        service.perform(record)
      end
    }.to_not raise_error
  end

  it "updates the record after sync" do
    VCR.use_cassette('external_name_sync') do
      service.perform(record)
    end
    expect(record.reload.synced_at).to be_present
  end
end
```

## VCR Conventions

- Cassette files live in `spec/cassettes/`
- Name cassettes descriptively: `netsuite_send_po`, `salesforce_sync_contact`
- Record once, replay always — commit cassette files to git
- Use `VCR.use_cassette('name') { block }` inline

## RX Reference

- `app/services/netsuite/` — NetSuite ERP integration
- `app/services/salesforce/` — Salesforce CRM integration
- `spec/services/netsuite/purchase_order_spec.rb` — VCR usage example
