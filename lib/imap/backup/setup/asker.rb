module Imap::Backup
  class Setup; end

  Setup::Asker = Struct.new(:highline) do
    EMAIL_MATCHER = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]+$/i.freeze

    def initialize(highline)
      super
    end

    def email(default = "")
      highline.ask("email address: ") do |q|
        q.default               = default
        q.readline              = true
        q.validate              = EMAIL_MATCHER
        q.responses[:not_valid] = "Enter a valid email address "
      end
    end

    def password
      password     = highline.ask("password: ")        { |q| q.echo = false }
      confirmation = highline.ask("repeat password: ") { |q| q.echo = false }
      if password != confirmation
        return nil if !highline.agree(
          "the password and confirmation did not match.\nContinue? (y/n) "
        )

        return self.password
      end
      password
    end

    def backup_path(default, validator)
      highline.ask("backup directory: ") do |q|
        q.default  = default
        q.readline = true
        q.validate = validator
        q.responses[:not_valid] = "Choose a different directory "
      end
    end

    def self.email(default = "")
      new(Setup.highline).email(default)
    end

    def self.password
      new(Setup.highline).password
    end

    def self.backup_path(default, validator)
      new(Setup.highline).backup_path(default, validator)
    end
  end
end
