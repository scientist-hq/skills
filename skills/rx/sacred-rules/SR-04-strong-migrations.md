# SR-04: Strong Migrations

**Level:** MUST follow
**Category:** Database Safety

## Rule

All database migrations must be safe for zero-downtime deployments. Use `strong_migrations` gem patterns. Never run unsafe operations without `safety_assured` and a documented reason.

## Why

RX runs on production PostgreSQL with zero-downtime deploys. Unsafe migrations (locking tables, removing columns without ignoring them first) can take down the platform during deployment.

## Patterns

### Adding an index to a large table

```ruby
class AddIndexToOrders < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :orders, :organization_id,
              algorithm: :concurrently
  end
end
```

### Adding a foreign key on a new table

```ruby
class CreateInventoryCatalogsLegalEntities < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_catalogs_legal_entities do |t|
      t.integer :inventory_catalog_id, null: false
      t.integer :legal_entity_id, null: false
      t.timestamps

      t.index %i[inventory_catalog_id legal_entity_id],
              unique: true,
              name: 'index_inv_catalogs_le_on_catalog_and_entity'
    end

    safety_assured do
      add_foreign_key :inventory_catalogs_legal_entities, :inventory_catalogs
      add_foreign_key :inventory_catalogs_legal_entities, :legal_entities
    end
  end
end
```

### Removing a column

```ruby
class RemoveBasePriceFromMilestone < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      remove_column :milestones, :base_price, :decimal
    end
  end
end
```

**Important:** Before removing a column, first add it to `ignored_columns` in the model and deploy. Then remove the column in a subsequent migration.

## Unsafe Operations (never do without safety_assured + reason)

- `remove_column` without prior `ignored_columns`
- `add_index` without `algorithm: :concurrently` on large tables
- `change_column` (locks the table)
- `rename_column` / `rename_table` (breaks running code)
- `add_foreign_key` on existing large tables without `validate: false`

## Validation

```bash
# strong_migrations will raise during migrate if unsafe
bundle exec rails db:migrate
```
