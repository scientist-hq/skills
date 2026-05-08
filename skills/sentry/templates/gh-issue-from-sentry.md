# Fallback GH Issue Template

Used by the issue-filer agent when the affected repo has no `.github/ISSUE_TEMPLATE/` directory or no template that fits. If the repo has its own template, prefer that.

---

## Title

`<exception class>: <one-line summary> in <area>`

Examples:
- `NoMethodError: undefined method '+' for nil in OrderTotal calculation`
- `ActiveRecord::RecordNotFound when accessing /admin/users/:id with stale session`

## Body

```markdown
## Summary

One-paragraph plain-language description of what's going wrong, who's affected, and how often.

## Sentry

- Issue: <SENTRY_URL>
- ID: `<SENTRY_ID>`
- First seen: <DATE>
- Last seen: <DATE>
- Event count: <N>
- Environment(s): <ENV_LIST>
- Affected release(s): <RELEASE_LIST>

## Exception

```
<EXCEPTION_CLASS>: <EXCEPTION_MESSAGE>
```

## Stack trace

<details>
<summary>Top frames</summary>

```
<STACK_TRACE>
```

</details>

## Reproduction

TODO: <leave a clear marker if reproduction steps aren't yet known — the investigator agent will fill this in if it can>

## Suggested next steps

TODO: <one or two bullets, only if the investigator surfaced concrete suggestions>
```

## Notes for the issue-filer agent

- The body uses fenced code blocks for stack traces; preserve the original whitespace.
- Do **not** add labels in the body. Labels come from the repo's template metadata or are added later by humans.
- Do **not** include `@mentions`, assignees, or reviewer hints (R-03).
- If a field is genuinely unknown (e.g., "affected release" not in Sentry), write the field name with `unknown` rather than omitting it — easier for a human to fill in later.
