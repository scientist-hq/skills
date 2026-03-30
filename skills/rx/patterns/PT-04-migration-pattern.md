# PT-04: Migration Pattern

See also: SR-04 (Strong Migrations)

## New Table with Foreign Keys

```ruby
class CreateFeatureRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_records do |t|
      t.integer :organization_id, null: false
      t.string :name, null: false
      t.integer :status, default: 0
      t.timestamps

      t.index :organization_id
      t.index %i[organization_id name], unique: true
    end

    safety_assured do
      add_foreign_key :feature_records, :organizations
    end
  end
end
```

## Add Index (Concurrent)

```ruby
class AddIndexToFeatureRecords < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :feature_records, :status,
              algorithm: :concurrently
  end
end
```

## Add Column

```ruby
class AddDescriptionToFeatureRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :feature_records, :description, :text
  end
end
```

## Remove Column (Two-Step)

**Step 1: Deploy with ignored_columns**
```ruby
class FeatureRecord < ApplicationRecord
  self.ignored_columns += ["old_column"]
end
```

**Step 2: Migration after deploy**
```ruby
class RemoveOldColumnFromFeatureRecords < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :feature_records, :old_column, :string
    end
  end
end
```

## Conventions

- Always add indexes for foreign keys and frequently queried columns
- Use `null: false` for required fields
- Use `default:` for enum/status columns
- Name composite indexes descriptively when auto-name is too long
- Run `bundle exec rails db:migrate` to verify strong_migrations passes
