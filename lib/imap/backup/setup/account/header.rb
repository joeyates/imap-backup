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
      rows = [
        email,
        password,
        path,
        folders,
        mode,
        multi_fetch,
        server,
        connection_options,
        reset_seen_flags_after_fetch
      ].compact

      menu.header = <<~HEADER.chomp
        #{helpers.title_prefix} Account#{modified_flag}

        #{format_rows(rows)}

        Choose an action
      HEADER
    end

    private

    def modified_flag
      account.modified? ? "*" : ""
    end

    def email
      ["email", account.username]
    end

    def password
      masked_password =
        if (account.password == "") || account.password.nil?
          "(unset)"
        else
          account.password.gsub(/./, "x")
        end
      ["password", masked_password]
    end

    def path
      # In order to handle backslashes, as Highline effectively
      # does an eval (!) on its templates, we need to doubly
      # escape them
      local_path = account.local_path.gsub("\\", "\\\\\\\\")
      ["path", local_path]
    end

    def folders
      items = account.folders || []
      list =
        if items.any?
          items.map { |f| f[:name] }.join(", ")
        else
          "(all folders)"
        end
      ["folders", list]
    end

    def mode
      value =
        if account.mirror_mode
          "mirror emails"
        else
          "keep all emails"
        end
      ["mode", value]
    end

    def multi_fetch
      return nil if account.multi_fetch_size == 1

      ["multi-fetch", account.multi_fetch_size]
    end

    def server
      ["server", account.server]
    end

    def connection_options
      return nil if !account.connection_options

      escaped = JSON.generate(account.connection_options)
      escaped.gsub!('"', '\"')
      ["connection options", "'#{escaped}'"]
    end

    def reset_seen_flags_after_fetch
      return nil if !account.reset_seen_flags_after_fetch

      ["changes to unread flags will be reset during download"]
    end

    def format_rows(rows)
      largest_label, _value = rows.max_by do |(label, value)|
        if value
          label.length
        else
          0
        end
      end
      rows.map do |(label, value)|
        format(
          "%-#{largest_label.length}<label>s %<value>s",
          {label: label, value: value}
        )
      end.join("\n")
    end

    def helpers
      Setup::Helpers.new
    end
  end
end
