require "imap/backup/setup/helpers"

module Imap::Backup
  class Setup; end
  class Setup::Account; end

  class Setup::Account::Header
    attr_reader :account
    attr_reader :menu

    def initialize(menu:, account:)
      @menu = menu
      @account = account
    end

    def run
      menu.header = <<~HEADER.chomp
        #{helpers.title_prefix} Account#{modified_flag}

        email   #{space}#{account.username}
        password#{space}#{masked_password}
        path    #{space}#{local_path}
        folders #{space}#{folders.map { |f| f[:name] }.join(', ')}#{multi_fetch_size}
        server  #{space}#{account.server}#{connection_options}#{reset_seen_flags_after_fetch}

        Choose an action
      HEADER
    end

    private

    def folders
      account.folders || []
    end

    def helpers
      Setup::Helpers.new
    end

    def modified_flag
      account.modified? ? "*" : ""
    end

    def multi_fetch_size
      "\nmulti-fetch #{account.multi_fetch_size}" if account.multi_fetch_size > 1
    end

    def connection_options
      return nil if !account.connection_options

      escaped = JSON.generate(account.connection_options)
      escaped.gsub!('"', '\"')
      "\nconnection options  '#{escaped}'"
    end

    def reset_seen_flags_after_fetch
      return nil if !account.reset_seen_flags_after_fetch

      "\nchanges to unread flags will be reset during download"
    end

    def space
      account.connection_options ? " " * 12 : " " * 4
    end

    def masked_password
      if (account.password == "") || account.password.nil?
        "(unset)"
      else
        account.password.gsub(/./, "x")
      end
    end

    def local_path
      # In order to handle backslashes, as Highline effectively
      # does an eval (!) on its templates, we need to doubly
      # escape them
      account.local_path.gsub("\\", "\\\\\\\\")
    end
  end
end
