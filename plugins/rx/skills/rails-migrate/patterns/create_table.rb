# Example: Creating a new table
#
# Key conventions:
# - t.uuid for a natural key (gen_random_uuid())
# - null: false on required columns
# - explicit foreign_key: { to_table: } when association name differs from table name
# - on_delete: :cascade when orphaned rows would be invalid
# - t.timestamps always included
# - indexes on FKs are automatic via t.references; add extra indexes for query patterns

class CreateDocumentApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :document_approvals do |t|
      t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false

      t.references :document, null: false, foreign_key: true, index: true
      t.references :approver, null: false, foreign_key: { to_table: :users }, index: true
      t.references :organization, null: false, foreign_key: true, index: true

      t.string :status, null: false, default: "pending"
      t.text :notes
      t.datetime :decided_at

      t.timestamps
    end

    add_index :document_approvals, :uuid, unique: true
    add_index :document_approvals, [:document_id, :status]
  end
end
