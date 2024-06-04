module Imap; end

module Imap::Backup
  class Setup; end

  # Implements interactively requesting information from the user
  class Setup::Asker
    # @param highline [Higline] the configured Highline instance
    def initialize(highline)
      @highline = highline
    end

    # Asks for a email address
    #
    # @param default [String] the existing email address
    # @return [String] the email address
    def email(default = "")
      highline.ask("email address: ") do |q|
        q.default               = default
        q.validate              = EMAIL_MATCHER
        q.responses[:not_valid] = "Enter a valid email address "
      end
    end

    # Asks for a password
    #
    # @return [String] the password
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

    # Asks for a email address using the configured menu handler
    #
    # @param default [String] the existing email address
    # @return [String] the email address
    def self.email(default = "")
      new(Setup.highline).email(default)
    end

    # Asks for a password using the configured menu handler
    #
    # @return [String] the password
    def self.password
      new(Setup.highline).password
    end

    private

    EMAIL_MATCHER = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]+$/i

    attr_reader :highline
  end
end
