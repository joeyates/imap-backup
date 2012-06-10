# -*- encoding: utf-8 -*-
$:.unshift(File.expand_path('../lib/', __FILE__))
require 'imap/backup/version'

Gem::Specification.new do |gem|
  gem.authors       = ['Joe Yates']
  gem.email         = ['joe.g.yates@gmail.com']
  gem.description   = %q{Backup GMail, or any other IMAP email service, to disk.}
  gem.summary       = %q{Backup GMail (or other IMAP) accounts to disk}
  gem.homepage      = 'https://github.com/joeyates/imap-backup'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = 'imap-backup'
  gem.require_paths = ['lib']
  gem.version       = Imap::Backup::VERSION

  gem.add_runtime_dependency 'rake'
  if RUBY_VERSION < '1.9'
    gem.add_runtime_dependency 'json'
  end

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-doc'
  gem.add_development_dependency 'rspec',  '>= 2.3.0'
  if RUBY_VERSION < '1.9'
    gem.add_development_dependency 'rcov'
  else
    gem.add_development_dependency 'simplecov'
  end
  
end

