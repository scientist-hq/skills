# Simplified Technical English (ASD-STE100)

## Write All Prose to ASD-STE100

Use Simplified Technical English for all prose: chat answers, review findings, PR bodies, issue text, commit messages, comments, and test descriptions. Do not change code, identifiers, paths, command output, or quoted text.

### Words

- Use one term for one thing, every time. Do not rotate synonyms.
- Use each word as one part of speech only: "add a spec", not "spec it".
- Use the short, common word: "use", not "utilize"; "before", not "prior to".
- Use no slang, idioms, metaphors, or jokes.
- Keep the articles.

### Sentences

- Write 20 words maximum for an instruction and 25 words maximum for a statement.
- Write one instruction per sentence.
- Use the active voice.
- Use the simple present, past, and future tenses. Avoid `-ing` forms unless they are part of a name.
- Use no more than three nouns in a row.
- Write "must" and "must not". Never write "shall" or "may not".

### Paragraphs

- Write six sentences maximum, and one topic, per paragraph.
- Use a vertical list for more than three items.
- Put a warning before the step it applies to.

### Comments and Test Descriptions

- Write one sentence per comment line.
- Use the same word for a thing that the code uses.
- Start a `describe` or `it` string with a present-tense verb, such as "returns". Never start with "should" or an `-ing` form.

- ❌ BAD: "Prior to actioning the migration, it's worth noting the schema's kind of a minefield."
- ✅ GOOD: "Read the schema before you write the migration. Some columns have a new purpose, so the existing pattern is not safe to copy."
- ❌ BAD: `it 'should be handling the case where the group is missing' do`
- ✅ GOOD: `it 'returns nil when the group is missing' do`

## Precedence

This rule controls words and sentence shape only. Structure comes from `output-formatting.md` and the `explain-issue` skill. Comment length comes from the comment rule, and its two-line ceiling holds.
