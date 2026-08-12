Audit and fix the `@scientist/ui` public surface — `packages/ui/src/index.ts` and `packages/ui/src/types.ts` — to enforce these invariants:

**`index.ts`**
- Only component/value exports (`export { Foo }` or `export { Foo, Bar }`)
- No type exports (those belong in `types.ts`)
- One export statement per exported name (split grouped exports into individual lines)
- All exports in alphabetical order by exported name

**`types.ts`**
- Only type exports (`export type { Foo }`)
- No value exports (those belong in `index.ts`)
- One export statement per exported type (split grouped exports into individual lines)
- All exports in alphabetical order by exported type name

## Workflow

1. Read both files in full
2. Parse every export line and check each rule above
3. Report all violations found before making any changes — list each one with the line number and which rule it breaks
4. Fix all violations in one pass per file:
   - Split any grouped exports onto individual lines
   - Move misplaced exports to the correct file
   - Sort all exports alphabetically by exported name
   - Preserve the existing import paths exactly — do not change source paths
5. Write the corrected files
6. Re-read both files and confirm: no violations remain, all exports alphabetical, one per line, correct file

## Rules for alphabetical ordering

Sort by the **exported name** (the identifier after `{`), case-insensitively, ignoring the `type` keyword. When two names would sort identically (e.g. a value export and a type export of the same name), the value export in `index.ts` and the type export in `types.ts` each sort independently within their own file.

## What NOT to change

- Do not alter import paths
- Do not add or remove exports — only move, split, and reorder
- Do not touch any file other than `index.ts` and `types.ts`
- Do not add comments or blank lines between exports (preserve any existing section comments)
