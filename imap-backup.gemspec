$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
require "imap/backup/version"

Gem::Specification.new do |gem|
  gem.name          = "imap-backup"
  gem.description   = "Backup GMail, or any other IMAP email service, to disk."
  gem.summary       = "Backup GMail (or other IMAP) accounts to disk"
  gem.authors       = ["Joe Yates"]
  gem.email         = ["joe.g.yates@gmail.com"]
  gem.homepage      = "https://github.com/joeyates/imap-backup"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ["lib"]
  gem.version       = Imap::Backup::VERSION

  gem.add_runtime_dependency "rake"
  gem.add_runtime_dependency "highline"
  gem.add_runtime_dependency "mail"

  gem.add_development_dependency "codeclimate-test-reporter", "~> 0.4.8"
  gem.add_development_dependency "rspec", ">= 3.0.0"
  gem.add_development_dependency "rubocop-rspec"
  gem.add_development_dependency "simplecov"
end
