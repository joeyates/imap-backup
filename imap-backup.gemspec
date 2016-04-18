# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'imap/backup/version'

Gem::Specification.new do |gem|
  gem.name          = 'imap-backup'
  gem.description   = %q{Backup GMail, or any other IMAP email service, to disk.}
  gem.summary       = %q{Backup GMail (or other IMAP) accounts to disk}
  gem.authors       = ['Joe Yates']
  gem.email         = ['joe.g.yates@gmail.com']
  gem.homepage      = 'https://github.com/joeyates/imap-backup'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ['lib']
  gem.version       = Imap::Backup::VERSION

  gem.add_runtime_dependency 'rake'
  gem.add_runtime_dependency 'highline'
  if RUBY_VERSION > '2'
    gem.add_runtime_dependency 'mail'
  else
    gem.add_runtime_dependency 'mime-types', '~> 2.6'
    gem.add_runtime_dependency 'mail', '~> 2.6.3'
  end

  gem.add_development_dependency 'codeclimate-test-reporter', '~> 0.4.8'
  gem.add_development_dependency 'rspec',  '>= 3.0.0'
  gem.add_development_dependency 'simplecov'
end
