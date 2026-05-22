---
name: searchkick
description: Rules for working with Searchkick models, specifically avoiding bulk database operations that bypass Elasticsearch reindexing callbacks.
---

# Searchkick

## Bulk Operations Bypass Reindexing

**NEVER use bulk database operations on Searchkick models without reindexing**

- `update_all`, `delete_all`, `insert_all`, and direct SQL bypass ActiveRecord callbacks
- Searchkick relies on those callbacks to keep Elasticsearch in sync
- The result is stale search results that don't reflect the database

**Methods to avoid:**
- `Model.update_all(...)`
- `Model.delete_all`
- `Model.insert_all(...)`
- `ActiveRecord::Base.connection.execute(...)`

**Safe alternatives:**
- ✅ GOOD: `records.each { |r| r.update!(field: value) }` — triggers callbacks
- ✅ ACCEPTABLE: `Model.update_all(...); Model.reindex` — bulk op followed by explicit reindex

**Examples:**
- ❌ BAD: `Pg::Certification.where(name: 'Test').update_all(region: 'au')`
- ✅ GOOD: `Pg::Certification.where(name: 'Test').each { |c| c.update!(region: 'au') }`
- ✅ ACCEPTABLE: `Pg::Certification.where(name: 'Test').update_all(region: 'au'); Pg::Certification.reindex`
