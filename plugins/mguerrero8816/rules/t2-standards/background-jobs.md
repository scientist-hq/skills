# Background Jobs

## Queue Assignment

- **Do NOT add `queue_as` to new jobs** — the majority of jobs in the codebase omit it and rely on the default queue
- Only specify a queue if there is a specific, known reason (e.g. high memory jobs like data imports use `:high_memory`)
- Do not flag missing `queue_as` as an issue during code reviews
