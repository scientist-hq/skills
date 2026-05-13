# Example: Removing columns
#
# Key conventions:
# - Always wrap remove_column in safety_assured (strong_migrations blocks it otherwise)
# - Pass the column type as a second argument so the migration is reversible
# - remove_columns for multiple columns in one shot
# - Ignore the column in the model before deploying (ignored_columns) so reads don't break
#   between deploy and migration run — that's a separate model change, not in the migration

class RemoveDeprecatedFieldsFromOrders < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      # Single column — type arg makes it reversible
      remove_column :orders, :legacy_po_number, :string

      # Multiple columns at once
      remove_columns :orders,
                     :old_sync_status,
                     :old_sync_attempted_at,
                     :old_sync_error
    end
  end
end
