- The `ARCHITECTURE.md` file contains a description of the project.

# Ruby Code

- Use 2 spaces for indentation.
- The maximum allowed line length is 100 characters.
- Never use `unless` in the codebase.
- Never use the ternary operator `x ? y : z`, use multiline `if` instead.
- Where possible do one thing per line:
  - Don't nest function calls, use temporary variables.

## Modules and Classes

- Format modules as follows:

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

- In specs, prefer one assertion per example.
- Avoid `double`, use `instance_double`.
- To get path for a unit spec, take the code path and remove the initial
  `lib/imap/backup/` add a `spec/unit/` prefix and add the suffix `_spec.rb`.
  Example: `lib/imap/backup/foo/bar.rb` → `spec/unit/foo/bar_spec.rb`.
