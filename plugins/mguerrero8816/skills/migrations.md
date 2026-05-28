---
description: Rules for generating and managing Rails database migrations, including timestamp hygiene, schema.rb cleanup, and FK type matching on legacy serial tables.
---

# Migrations

## Always Use the Rails Generator

**ALWAYS generate migration files with the Rails generator — never create them by hand:**

```bash
env -C /Users/mike/rx/rx bundle exec rails generate migration MigrationName
```

This gives you the correct timestamp automatically. Never hand-write the filename or its timestamp — the generator handles both.

## Timestamp Must Be Real

If for any reason a migration file must be created manually, use the actual current UTC time:

```bash
date -u +%Y%m%d%H%M%S
```

- **NEVER** use fake timestamps like `20260513000001` or any midnight/round-number timestamp
- Placeholder timestamps risk colliding with a teammate's migration and breaking the migration order

## Cleaning Up `schema.rb` After Running Migrations

The dev database is shared and may contain migrations from unmerged branches being reviewed locally. Running `db:migrate` will apply those too, adding unrelated tables and columns to `schema.rb`.

**ALWAYS** load and follow **`skills/database/clean-schema.md`** after running any migration — not just when you notice a diff.

## `safety_assured` — Required for Callable Defaults

`strong_migrations` cannot introspect lambda/proc defaults (e.g. `default: -> { "gen_random_uuid()" }`). It always requires `safety_assured` when a callable default is passed to `add_column`, regardless of whether the operation is actually safe.

**ALWAYS wrap `add_column` calls that use a callable default in `safety_assured`.**

For non-callable defaults and other operations, only add `safety_assured` if `strong_migrations` actually raises an error when you run the migration.

## No Loops — List Each Table Individually

**NEVER use a loop to apply the same operation across multiple tables.**

List each `add_column`, `add_index`, `create_table`, etc. call individually, one per table.

**Why:** Loops obscure what the migration actually does and make it harder to review, roll back selectively, or debug a failure mid-run.

## `t.references` on Legacy Serial Tables

**Do NOT use `t.references` when creating foreign keys pointing at legacy `id: :serial` (integer) tables**

Modern Rails defaults both `create_table` PKs and `t.references` columns to `bigint`. Legacy tables in this codebase (e.g. `providers`, `quote_groups`) were created with `id: :serial` — a 4-byte `integer`. PostgreSQL requires the FK column type to match the referenced PK type exactly, so a `bigint` FK against an `integer` PK will fail with a type mismatch error.

- **ALWAYS** use `t.integer :xxx_id, null: false` for FK columns on legacy serial tables
- Check `db/schema.rb` for `id: :serial` to confirm a table is legacy before deciding
