# Emphasized Rules

- Never use `unless` in the codebase.
- Use `bin/unit-test-path` to obtain the unit tast path for a code file.
- In tests, never use `double`, use `instance_double` instead.

# Overall

- The `ARCHITECTURE.md` file contains a description of the project,
- `docs/tesing.md` explains how to run tests.

# Ruby Code

- Use 2 spaces for indentation.
- The maximum allowed line length is 100 characters.
- Never use the ternary operator `x ? y : z`, use multiline `if` instead.
- Where possible do one thing per line:
  - Don't nest function calls, use temporary variables.

## Modules and Classes

- Use accessors for class instance variables.
- Avoid accessing instance variables directly (with @) except in `initialize` and
  in memoized getters.
- Format classes and modules as follows:

```ruby
module Imap; end

module Imap::Backup
  module Foo; end

  # Documentation string.
  class Foo::Bar
    ...
  end
end
```

# Testing

- When creating new tests, use existing tests in the same directory as examples, if available.
- In tests, prefer one assertion per example.
- Never test private methods, instead write tests for public methods that exercise the private methods.
- When returning a value from RSPec's `allow` use a block, don't use `and_return`.

## Test Coverage

- To decide where tests are needed, use `bin/lines-without-coverage`. If all lines
  are covered, use `bin/branches-without-covarage`.
