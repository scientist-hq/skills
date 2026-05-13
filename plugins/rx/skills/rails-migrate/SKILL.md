---
description: Generate, review, and run Rails database migrations following RX team conventions (strong_migrations, concurrent indexes, safety_assured, backfills). Iterates until the migration looks right, then runs it and updates schema.rb.
when_to_use: When the user wants to add, change, or remove database columns, tables, indexes, or constraints. Triggered by descriptions like "add a column", "create a table", "add an index", "drop a column", "backfill data", or "write a migration".
---

You are writing a Rails database migration for the RX codebase, following the team's conventions exactly. Your job is:

1. **Generate** a migration file from the user's description
2. **Review** it together and iterate until it's right
3. **Run** it to update `schema.rb`
4. **Roll back and re-run** if changes are needed after the fact

Work through these stages in order.

---

## Stage 1 — Understand what's needed

If the user gave `$ARGUMENTS`, use that as the starting description. Ask one targeted clarifying question if something is ambiguous (e.g., nullability, default values, whether a backfill is needed). Don't ask for info you can infer.

---

## Stage 2 — Generate the migration

Use `bundle exec rails generate migration <MigrationName>` to generate the file with the correct timestamp, then edit it to match the required content. Never create the file by hand without the generator — the timestamp must come from Rails.

The migration name should be descriptive and match Rails conventions: `AddColumnToTable`, `CreateTableName`, `RemoveColumnFromTable`, `BackfillColumnOnTable`, `AddIndexToTable`.

Reference the examples in `patterns/` for each migration type before writing. They reflect real RX patterns and should be your starting point.

### Conventions to follow

**Columns**
- Add `null: false` unless the column genuinely needs to allow nulls
- Add `default:` when the column has a sensible default (e.g., booleans, status strings, jsonb `{}`)
- Use `t.timestamps` on new tables
- Prefer `t.string` over `t.text` for short values; use `t.text` for long free-form text
- Use `t.jsonb` (not `t.json`) for JSON columns, with `default: {}`
- Use `t.uuid :uuid, default: -> { 'gen_random_uuid()' }, null: false` when a UUID natural key is needed

**References / Foreign Keys**
- Use `t.references :thing, null: false, foreign_key: true, index: true` in `create_table`
- When the FK table name differs from the association name: `foreign_key: { to_table: :actual_table_name }`
- Add `on_delete: :cascade` when orphaned rows would be invalid
- Use `add_reference :table, :thing, index: { algorithm: :concurrently }` (with `disable_ddl_transaction!`) when adding a reference to an existing table

**Indexes**
- Always add indexes on foreign key columns and columns used in WHERE clauses or ORDER BY
- Adding an index to an existing table requires `disable_ddl_transaction!` at the class level and `algorithm: :concurrently`
- Indexes inside `create_table` blocks do NOT need `algorithm: :concurrently`
- Use `if_not_exists: true` when the index might already exist (e.g., idempotent migrations)
- Name long indexes explicitly with `name:` to avoid PostgreSQL's 63-char limit

**strong_migrations rules**
- Adding a column with a non-null default on a large existing table → wrap in `safety_assured` (Postgres 11+ handles this safely, but strong_migrations still flags it; always add a comment explaining why it's safe)
- `remove_column` → always `safety_assured { remove_column ... }`
- Renaming a column → avoid; prefer add + backfill + remove in separate migrations
- Adding NOT NULL constraint to existing column → use `add_not_null_constraint` + `validate_not_null_constraint` in separate migrations
- `change_column` → almost always needs `safety_assured`

**Backfills**
- Data migrations belong in a separate migration from the schema change (or in `up`/`down` if tightly coupled)
- Use `Model.update_all(...)` or `safety_assured { execute <<~SQL }` for large backfills — never `.each` in migrations
- Wrap backfill SQL in `safety_assured` when needed
- Add `# rubocop:disable` comments if the model constant is only referenced in the migration

**`up` / `down` vs `change`**
- Use `change` for simple reversible operations (add_column, create_table, add_index)
- Use `up` / `down` when the migration is not auto-reversible (remove_column, data backfills, complex changes)

---

## Stage 3 — Show and review

Show the user the full generated migration file content. Ask: **"Does this look right, or anything to adjust?"**

Do not run anything yet.

---

## Stage 4 — Run the migration

Once the user approves, run:

```
cd rx && bundle exec rails db:migrate
```

Show the output. If it succeeds, confirm that `rx/db/schema.rb` was updated.

---

## Stage 5 — Iterate if needed

If the user wants changes after seeing the result:

1. Roll back: `bundle exec rails db:rollback STEP=1`
2. Edit the migration file
3. Re-run: `bundle exec rails db:migrate`

Repeat until correct.

---

## Rules

- Always generate with `rails generate migration`, then edit — never skip the generator
- Never use the `Pg::` namespace for model constants referenced in migrations
- Prefix all Rails/Rake commands with `bundle exec`
- Run commands from the `rx/` subdirectory (the Rails app root), not the repo root
- If `strong_migrations` blocks a migration, explain why and propose the safe alternative — don't blindly add `safety_assured` without understanding the risk
- Keep migrations focused: one schema concern per migration; backfills in their own migration unless trivially small
