require "json"

require "imap/backup/setup/helpers"

module Imap; end

module Imap::Backup
  class Setup; end
  class Setup::Account; end

  # Displays the header to the account modification menu
  class Setup::Account::Header
    # @param menu [Highline::Menu] the menu
    # @param account [Account] an Account
    def initialize(menu:, account:)
      @menu = menu
      @account = account
    end

    # Displays the header
    #
    # @return [void]
    def run
      rows = [
        email,
        password,
        server,
        connection_options,
        mode,
        path,
        folders,
        multi_fetch,
        reset_seen_flags_after_fetch,
        status_row
      ].compact

      menu.header = <<~HEADER.chomp
        #{helpers.title_prefix} #{I18n.t('setup.account.title')}#{modified_flag}

        #{format_rows(rows)}

        #{I18n.t('setup.account.connection_configuration')}
      HEADER
    end

    private

    attr_reader :account
    attr_reader :menu

    def modified_flag
      account.modified? ? "*" : ""
    end

    def email
      [I18n.t("setup.account.email"), account.username]
    end

    def password
      masked_password =
        if (account.password == "") || account.password.nil?
          I18n.t("setup.account.password_unset")
        else
          account.password.gsub(/./, "x")
        end
      [I18n.t("setup.account.password"), masked_password]
    end

    def path
      # In order to handle backslashes, as Highline effectively
      # does an eval (!) on its templates, we need to doubly
      # escape them
      local_path = account.local_path.gsub("\\", "\\\\\\\\")
      [I18n.t("setup.account.path"), local_path]
    end

    def folders
      label =
        if account.folder_blacklist
          I18n.t("setup.account.exclude")
        else
          I18n.t("setup.account.include")
        end
      items = account.folders || []
      list =
        case
        when items.any?
          items.join(", ")
        when !account.folder_blacklist
          I18n.t("setup.account.all_folders")
        else
          I18n.t("setup.account.no_folders_warning")
        end
      [label, list]
    end

    def mode
      value =
        if account.mirror_mode
          I18n.t("setup.account.mirror_emails")
        else
          I18n.t("setup.account.keep_all_emails")
        end
      [I18n.t("setup.account.mode"), value]
    end

    def multi_fetch
      return nil if account.multi_fetch_size == 1

      [I18n.t("setup.account.multi_fetch"), account.multi_fetch_size]
    end

    def server
      [I18n.t("setup.account.server"), account.server]
    end

    def connection_options
      return nil if !account.connection_options

      escaped = JSON.generate(account.connection_options)
      escaped.gsub!('"', '\"')
      [I18n.t("setup.account.connection_options"), "'#{escaped}'"]
    end

    def reset_seen_flags_after_fetch
      return nil if !account.reset_seen_flags_after_fetch

      [I18n.t("setup.account.reset_seen_flags_message")]
    end

    def status_row
      return nil if account.status == "active"

      [I18n.t("setup.account.status"), account.status]
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
