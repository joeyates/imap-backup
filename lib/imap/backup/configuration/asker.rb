# encoding: utf-8

module Imap::Backup::Configuration
  module Asker
    EMAIL_MATCHER = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i

    def self.email(default = '')
      Setup.highline.ask('email address: ') do |q|
        q.default               = default
        q.readline              = true
        q.validate              = EMAIL_MATCHER
        q.responses[:not_valid] = 'Enter a valid email address '
      end
    end

    def self.password
      password     = Setup.highline.ask('password: ')        { |q| q.echo = false }
      confirmation = Setup.highline.ask('repeat password: ') { |q| q.echo = false }
      if password != confirmation
        return nil unless Setup.highline.agree("the password and confirmation did not match.\nContinue? (y/n) ")
        return self.password
      end
      password
    end

    def self.backup_path(default, validator)
      Setup.highline.ask('backup directory: ') do |q|
        q.default  = default
        q.readline = true
        q.validate = validator
        q.responses[:not_valid] = 'Choose a different directory '
      end
    end
  end
end
