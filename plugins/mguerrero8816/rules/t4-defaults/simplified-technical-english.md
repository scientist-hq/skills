# Simplified Technical English (ASD-STE100)

## Write All Prose to ASD-STE100

Write every sentence in Simplified Technical English: chat answers, explanations, review findings, PR bodies, issue text, commit messages, and the prose inside code. Code itself does not change. Identifiers, file paths, command output, and quoted text stay exactly as they are.

### Words

- One word, one meaning. Choose one term for a thing and use that term every time. Do not rotate synonyms (request / ticket / ask).
- Use each word in one part of speech only. Do not make a verb out of a noun: "add a spec", not "spec it"; "take action", not "action it".
- Use the short, common word. Write "use" not "utilize", "before" not "prior to", "start" not "initiate", "about" not "regarding".
- No slang, idioms, metaphors, or jokes.
- Keep the articles. Do not remove "the" or "a" to make a sentence shorter.

### Sentences

- 20 words maximum for an instruction. 25 words maximum for a statement of fact.
- One instruction per sentence. Two actions need two sentences.
- Use the active voice. Name the thing that does the action.
- Use simple tenses only: present, past, and future. Avoid `-ing` forms unless they are part of a name.
- Three nouns in a row is the limit. Break up longer noun clusters with prepositions.
- Write "must" for a requirement and "must not" for a prohibition. Never write "shall" or "may not".

### Paragraphs

- Six sentences maximum per paragraph. One topic per paragraph.
- Use a vertical list for more than three steps, conditions, or items.
- Put a warning before the step that it applies to, never after it.

**Examples:**
- ❌ BAD: "Prior to actioning the migration, it's worth noting the schema's kind of a minefield — a lot of the columns were repurposed over the years, so blindly following the existing pattern will bite you."
- ✅ GOOD: "Read the schema before you write the migration. Some columns have a new purpose, so the existing pattern is not safe to copy."
- ❌ BAD: "The spec is green, so we're good."
- ✅ GOOD: "The spec passes."
- ❌ BAD: "customer purchase order line item quantity field"
- ✅ GOOD: "the quantity field on a customer purchase order line item"

### Comments and Test Descriptions

The rules above apply to every comment you write, in every language: Ruby, JavaScript, ERB, HAML, SQL, and YAML. They also apply to RSpec and Jest `describe`, `context`, and `it` strings.

- Write one sentence per comment line. A comment that needs a second clause needs a second sentence.
- Name the same thing with the same word that the code uses. Do not call a `quoted_ware` a "line item" in the comment above it.
- Start a `describe` or `it` string with a simple present-tense verb: "returns", "raises", "skips". Do not write "should" or an `-ing` form.

**Examples:**
- ❌ BAD: `# Bailing out early here since the callback ordering means the association isn't loaded yet and we'd end up double-writing.`
- ✅ GOOD: `# The callback runs before the association loads. A second write would follow, so return first.`
- ❌ BAD: `it 'should be handling the case where the group is missing' do`
- ✅ GOOD: `it 'returns nil when the group is missing' do`

## Precedence

This rule controls word choice and sentence shape. It does not replace the other output rules. Structure, ordering, and emphasis come from `output-formatting.md` and the `explain-issue` skill. Comment length and placement come from the comment preferences rule: the two-line ceiling holds, and this rule only decides the words inside it. Keep the inline `file.rb:line` references and the bold lead-ins that those rules require.
