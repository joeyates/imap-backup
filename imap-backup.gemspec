$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
require "imap/backup/version"

Gem::Specification.new do |gem|
  gem.name          = "imap-backup"
  gem.description   = "Backup GMail, or any other IMAP email service, to disk."
  gem.summary       = "Backup GMail (or other IMAP) accounts to disk"
  gem.authors       = ["Joe Yates"]
  gem.email         = ["joe.g.yates@gmail.com"]
  gem.homepage      = "https://github.com/joeyates/imap-backup"
  gem.licenses      = ["MIT"]
  gem.version       = Imap::Backup::VERSION

  gem.files         = %w[bin/imap-backup]
  gem.files         += Dir.glob("docs/*.md")
  gem.files         += Dir.glob("lib/**/*.rb")
  gem.files         += %w[imap-backup.gemspec]
  gem.files         += %w[LICENSE README.md]

  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.require_paths = ["lib"]
  gem.required_ruby_version = ">= 2.6"

  gem.add_runtime_dependency "highline"
  gem.add_runtime_dependency "mail"
  gem.add_runtime_dependency "net-imap", ">= 0.3.2"
  gem.add_runtime_dependency "net-smtp"
  gem.add_runtime_dependency "os"
  gem.add_runtime_dependency "rake"
  gem.add_runtime_dependency "thor", "~> 1.1"
  gem.add_runtime_dependency "thunderbird", ">= 0.0.0"

  gem.add_development_dependency "aruba", ">= 0.0.0"
  gem.add_development_dependency "pry-byebug"
  gem.add_development_dependency "rspec", ">= 3.0.0"
  gem.add_development_dependency "rubocop-rspec"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "yard"

  gem.metadata = {
    "rubygems_mfa_required" => "true"
  }
end
