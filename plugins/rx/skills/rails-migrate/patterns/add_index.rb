# Example: Adding an index to an existing table
#
# Key conventions:
# - disable_ddl_transaction! at the class level (required for concurrently)
# - algorithm: :concurrently on every add_index (avoids table lock in production)
# - if_not_exists: true when the index may already exist (idempotent re-runs)
# - Explicit name: when the auto-generated name would exceed 63 chars

class AddIndexesToTrials < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Single-column index
    add_index :trials, :status, algorithm: :concurrently

    # Composite index for a common query pattern
    add_index :trials, [:organization_id, :status], algorithm: :concurrently

    # Partial index
    add_index :trials, :started_at,
              where: "started_at IS NOT NULL",
              algorithm: :concurrently

    # Long name would exceed 63 chars — provide an explicit name
    add_index :trials, [:organization_id, :provider_id, :created_at],
              name: "index_trials_on_org_provider_created_at",
              algorithm: :concurrently
  end
end
