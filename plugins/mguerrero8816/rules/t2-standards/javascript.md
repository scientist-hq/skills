# JavaScript Code Standards

## Strict Equality (`eqeqeq`)

Always use `===` and `!==`, never `==` or `!=`. Change loose equality in code that you copy from another file.

## Assign Every `new` (`no-new`)

Assign the result of every constructor to a variable, even if you do not use the variable.

- ❌ BAD: `new bootstrap.Dropdown(element, options);`
- ✅ GOOD: `const dropdown = new bootstrap.Dropdown(element, options);`
