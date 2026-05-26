---
description: Diagnose and fix schema.rb diffs caused by local DB state diverging from main — stray columns, missing columns, and gen_random_uuid search_path noise.
---

## Goal

Fix the local `rx_development` database so `rails db:schema:dump` produces output that exactly matches the committed `schema.rb` on main. Never edit `schema.rb` directly — the file must be a true reflection of the DB.

## Step 1 — See What's Different

```bash
git diff -- rx/db/schema.rb
```

Run from the repo root. Categorize each chunk before touching anything.

## Step 2 — Identify the Table and Column

The diff shows the working-tree schema (post-dump). To find which `create_table` block a changed column belongs to, check the committed version:

```bash
git show HEAD:rx/db/schema.rb | grep -n "column_name"
git show HEAD:rx/db/schema.rb | grep -n "create_table" | awk -F: '{if ($1 <= LINE) print}' | tail -1
```

Replace `LINE` with the line number from the first grep.

## Step 3 — Fix Each Category

### Missing column (in HEAD schema, absent from local DB)

A branch migration that drops a column was applied to your local DB but never merged to main.

```ruby
# via rails runner from rx/
conn = ActiveRecord::Base.connection
conn.add_column(:table_name, :column_name, :type)
```

Get the type from the committed schema — `t.boolean`, `t.string`, `t.integer`, etc. map directly to Ruby types.

### Extra column (in local DB, absent from HEAD schema)

A branch migration that adds a column was applied locally but never merged.

```ruby
conn.remove_column(:table_name, :column_name)
```

### `gen_random_uuid()` vs `public.gen_random_uuid()`

PostgreSQL search_path difference — cosmetic but causes a persistent diff. Fix by explicitly setting the default to the schema-qualified form:

```ruby
conn.execute("ALTER TABLE table_name ALTER COLUMN id SET DEFAULT public.gen_random_uuid()")
```

### Extra or missing table

Same root cause as extra/missing columns but at table level. Use `create_table` / `drop_table` via `rails runner`, or trace the migration from another branch and run it down.

### Version bump only (schema version changed, no structural diff)

A migration was applied locally that isn't on main yet. If the migration is yours and on a feature branch, that's expected — just revert schema.rb to HEAD for now:

```bash
git checkout -- rx/db/schema.rb
```

## Step 4 — Verify

Redump the schema and confirm the diff is gone:

```bash
cd rx && bundle exec rails db:schema:dump
git diff -- rx/db/schema.rb
```

No output means clean.

## Running from the Right Directory

All `bundle exec rails` commands must run from `rx/` (where the Gemfile lives), not the repo root. See [[bundle]] skill.
