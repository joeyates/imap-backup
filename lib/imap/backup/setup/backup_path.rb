module Imap; end

module Imap::Backup
  class Setup; end

  class Setup::BackupPath
    attr_reader :account
    attr_reader :config

    def initialize(account:, config:)
      @account = account
      @config = config
    end

    def run
      account.local_path = highline.ask("backup directory: ") do |q|
        q.default  = account.local_path
        q.readline = true
        q.validate = ->(path) { path_modification_validator(path) }
        q.responses[:not_valid] = "Choose a different directory "
      end
    end

    private

    def highline
      Setup.highline
    end

    def path_modification_validator(path)
      same = config.accounts.find do |a|
        a.username != account.username && a.local_path == path
      end
      if same
        Kernel.puts "The path '#{path}' is used to backup " \
                    "the account '#{same.username}'"
        false
      else
        true
      end
    end
  end
end
