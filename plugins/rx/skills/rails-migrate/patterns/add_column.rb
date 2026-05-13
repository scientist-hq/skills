# Example: Adding columns to an existing table
#
# Key conventions:
# - Simple add_column uses `change` (auto-reversible)
# - null: false with a default is fine on Postgres 11+ but strong_migrations flags it —
#   wrap in safety_assured and add a comment explaining why it's safe
# - Adding a nullable column with no default needs no safety_assured

class AddArchivedToProposals < ActiveRecord::Migration[8.0]
  def change
    # Nullable column — no safety concerns
    add_column :proposals, :archived_at, :datetime

    # Non-null with default on a large table: Postgres 11+ handles this as a metadata-only
    # change, so it won't lock. strong_migrations flags it anyway, hence safety_assured.
    safety_assured do
      add_column :proposals, :version, :integer, null: false, default: 1
    end
  end
end
