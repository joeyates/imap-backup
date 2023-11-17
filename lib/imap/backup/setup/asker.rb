module Imap; end

module Imap::Backup
  class Setup; end

  class Setup::Asker
    EMAIL_MATCHER = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]+$/i.freeze

    def initialize(highline)
      @highline = highline
    end

    def email(default = "")
      highline.ask("email address: ") do |q|
        q.default               = default
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

    def self.email(default = "")
      new(Setup.highline).email(default)
    end

    def self.password
      new(Setup.highline).password
    end

    private

    attr_reader :highline
  end
end
