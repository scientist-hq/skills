# Example: Backfilling data
#
# Key conventions:
# - Schema change and backfill live in separate migrations (this file is backfill-only)
# - Use update_all or raw SQL — never .each/.map in a migration (will time out on large tables)
# - Wrap SQL in safety_assured when strong_migrations would otherwise block it
# - Use up/down (not change) since data migrations aren't auto-reversible
# - Reference model constants directly (not Pg:: namespace); add a comment if the
#   constant only exists in this migration context

class BackfillDisplayNameOnUsers < ActiveRecord::Migration[8.0]
  def up
    # Simple case: derive value from existing columns
    User.update_all("display_name = CONCAT(first_name, ' ', last_name) WHERE display_name IS NULL")

    # Or with raw SQL for more complex logic
    safety_assured do
      execute <<~SQL
        UPDATE users
        SET display_name = CONCAT(first_name, ' ', last_name)
        WHERE display_name IS NULL
          AND first_name IS NOT NULL
      SQL
    end
  end

  def down
    safety_assured do
      execute "UPDATE users SET display_name = NULL"
    end
  end
end
