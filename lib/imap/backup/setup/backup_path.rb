module Imap; end

module Imap::Backup
  class Setup; end

  # Requests an updated backup path from the user
  class Setup::BackupPath
    # @param account [Account] an Account
    # @param config [Configuration] the application configuration
    def initialize(account:, config:)
      @account = account
      @config = config
    end

    # Asks the user for a backup path
    #
    # @return [void]
    def run
      account.local_path = highline.ask(I18n.t("setup.backup_path.prompt")) do |q|
        q.default  = account.local_path
        q.validate = ->(path) { path_modification_validator(path) }
        q.responses[:not_valid] = I18n.t("setup.backup_path.validation_error")
      end
    end

    private

    attr_reader :account
    attr_reader :config

    def highline
      Setup.highline
    end

    def path_modification_validator(path)
      same = config.accounts.find do |a|
        a.username != account.username && a.local_path == path
      end
      if same
        Kernel.puts I18n.t("setup.backup_path.path_in_use",
                           path: path, username: same.username)
        false
      else
        true
      end
    end
  end
end
