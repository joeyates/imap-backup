- The `ARCHITECTURE.md` file contains a description of the project.

# Ruby Code

- Use 2 spaces for indentation.
- The maximum allowed line length is 100 characters.
- Never use `unless` in the codebase.
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

## Testing

- In tests, prefer one assertion per example.
- Avoid `double`, use `instance_double`.
- To get path for a unit test, take the code path and remove the initial
  `lib/imap/backup/` add a `spec/unit/` prefix and add the suffix `_spec.rb`.
  Example: `lib/imap/backup/foo/bar.rb` → `spec/unit/foo/bar_spec.rb`.
- When creating new tests, use existing tests in the same directory as examples,
  if available.
- Never test private methods, instead write tests for public methods that exercise the
  private methods.