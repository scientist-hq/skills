# JavaScript Code Standards

## ESLint Strict Equality Rule

- **ALWAYS use strict equality**: Use `===` and `!==` instead of `==` and `!=` in JavaScript code
- **NEVER use loose equality**: The `==` operator will fail eslint checks with the `eqeqeq` rule
- **Check existing code patterns**: If copying code from existing files, update `==` to `===` even if the source uses loose equality

## ESLint No-New Rule

- **NEVER use `new` constructors for side effects without assigning to a variable**
- **ALWAYS assign constructor results to a variable**, even if you don't use the variable afterward
- The `no-new` ESLint rule will fail if constructors are called without assignment

**Examples:**
- ❌ BAD: `new bootstrap.Dropdown(element, options);`
- ✅ GOOD: `const dropdown = new bootstrap.Dropdown(element, options);`
- ❌ BAD: `new Modal(config);`
- ✅ GOOD: `const modal = new Modal(config);`
