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

  if RUBY_VERSION < '1.9'
    gem.add_runtime_dependency 'rake', '< 10.2.0'
  else
    gem.add_runtime_dependency 'rake'
  end
  gem.add_runtime_dependency 'highline'
  gem.add_runtime_dependency 'mail'
  if RUBY_VERSION < '1.9'
    gem.add_runtime_dependency 'json'
  end

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-doc'
  gem.add_development_dependency 'rspec',  '>= 2.12.0'
  if RUBY_VERSION < '1.9'
    gem.add_development_dependency 'rcov'
  else
    gem.add_development_dependency 'simplecov'
  end
end
