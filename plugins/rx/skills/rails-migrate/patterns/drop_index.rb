# Example: Removing an index from an existing table
#
# Key conventions:
# - disable_ddl_transaction! (required for algorithm: :concurrently)
# - algorithm: :concurrently avoids locking reads/writes during removal
# - Use remove_index with column: or name: — be explicit to avoid mistakes
# - `change` is reversible: Rails will re-add the index on rollback

class RemoveUnusedIndexFromQuotes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Remove by column name
    remove_index :quotes, column: :legacy_reference_id, algorithm: :concurrently

    # Remove by explicit name (safer when the index has a custom name)
    remove_index :quotes, name: "index_quotes_on_org_and_status", algorithm: :concurrently
  end
end
