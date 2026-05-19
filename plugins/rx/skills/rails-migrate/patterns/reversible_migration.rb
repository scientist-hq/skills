# Example: Reversible migration using up/down
#
# Use up/down instead of change when:
# - The migration contains remove_column (needs type hint for rollback)
# - There's a data migration step
# - The operation isn't auto-reversible (change_column, execute, etc.)
#
# Key conventions:
# - down should undo up exactly — test rollback before merging
# - column_exists? / index_exists? guards make migrations safe to re-run
# - safety_assured required for remove_column and change_column in both directions

class MigrateStatusToEnum < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Add new integer column
    add_column :contracts, :status_int, :integer, null: false, default: 0

    # Backfill from the old string column
    safety_assured do
      execute <<~SQL
        UPDATE contracts SET status_int = CASE status
          WHEN 'draft'     THEN 0
          WHEN 'active'    THEN 1
          WHEN 'expired'   THEN 2
          ELSE 0
        END
      SQL
    end

    # Index the new column
    add_index :contracts, :status_int, algorithm: :concurrently

    # Drop the old column once backfill is confirmed
    safety_assured do
      remove_column :contracts, :status, :string
    end
  end

  def down
    # Restore the string column
    add_column :contracts, :status, :string

    safety_assured do
      execute <<~SQL
        UPDATE contracts SET status = CASE status_int
          WHEN 0 THEN 'draft'
          WHEN 1 THEN 'active'
          WHEN 2 THEN 'expired'
          ELSE 'draft'
        END
      SQL

      remove_column :contracts, :status_int, :integer
    end
  end
end
