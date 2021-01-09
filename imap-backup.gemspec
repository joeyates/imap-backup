$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
require "imap/backup/version"

Gem::Specification.new do |gem|
  gem.name          = "imap-backup"
  gem.description   = "Backup GMail, or any other IMAP email service, to disk."
  gem.summary       = "Backup GMail (or other IMAP) accounts to disk"
  gem.authors       = ["Joe Yates"]
  gem.email         = ["joe.g.yates@gmail.com"]
  gem.homepage      = "https://github.com/joeyates/imap-backup"

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ["lib"]
  gem.required_ruby_version = [">= 2.4.0"]
  gem.version = Imap::Backup::VERSION

  gem.add_runtime_dependency "gmail_xoauth"
  gem.add_runtime_dependency "googleauth"
  gem.add_runtime_dependency "highline"
  gem.add_runtime_dependency "mail"
  gem.add_runtime_dependency "rake"

  gem.add_development_dependency "codeclimate-test-reporter", "~> 0.4.8"
  if RUBY_ENGINE == "jruby"
    gem.add_development_dependency "pry-debugger-jruby"
  else
    gem.add_development_dependency "pry-byebug"
  end
  gem.add_development_dependency "rspec", ">= 3.0.0"
  gem.add_development_dependency "rubocop-rspec"
  gem.add_development_dependency "simplecov"
end
