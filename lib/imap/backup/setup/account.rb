require "imap/backup/setup/account/header"
require "imap/backup/setup/asker"
require "imap/backup/setup/backup_path"
require "imap/backup/setup/connection_tester"
require "imap/backup/setup/email_changer"
require "imap/backup/setup/folder_chooser"

module Imap; end

module Imap::Backup
  class Setup; end

  # Handles interactive account setup
  class Setup::Account
    # @param config [Configuration] the application configuration
    # @param account [Account] an Account
    # @param highline [Higline] the configured Highline instance
    def initialize(config, account, highline)
      @account = account
      @config = config
      @highline = highline
    end

    # Shows the menu
    # @return [void]
    def run
      if !account.local_path
        account.local_path = File.join(config.path, account.username.tr("@", "_"))
      end

      catch :done do
        loop do
          Kernel.system("clear")
          create_menu
        end
      end
    end

    private

    attr_reader :account
    attr_reader :config
    attr_reader :highline

    def create_menu
      highline.choose do |menu|
        header menu
        modify_email menu
        modify_password menu
        modify_server menu
        modify_connection_options menu
        test_connection menu
        toggle_mirror_mode menu
        modify_backup_path menu
        toggle_folder_blacklist menu
        choose_folders menu
        modify_multi_fetch_size menu
        toggle_reset_seen_flags_after_fetch menu
        rotate_status menu
        delete_account menu
        show_help menu
        menu.choice(I18n.t("setup.return_to_main_menu")) { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def header(menu)
      Setup::Account::Header.new(menu: menu, account: account).run
    end

    def modify_email(menu)
      menu.choice(I18n.t("setup.account.modify_email")) do
        Setup::EmailChanger.new(account: account, config: config).run
      end
    end

    def modify_password(menu)
      menu.choice(I18n.t("setup.account.modify_password")) do
        password = Setup::Asker.password

        account.password = password if !password.nil?
      end
    end

    def modify_server(menu)
      menu.choice(I18n.t("setup.account.modify_server")) do
        server = highline.ask(I18n.t("setup.account.server_prompt"))
        account.server = server if !server.nil?
      end
    end

    def modify_connection_options(menu)
      menu.choice(I18n.t("setup.account.modify_connection_options")) do
        connection_options = highline.ask(I18n.t("setup.account.connection_options_prompt"))
        if !connection_options.nil?
          begin
            account.connection_options = connection_options
          rescue JSON::ParserError
            Kernel.puts I18n.t("setup.account.malformed_json")
            highline.ask I18n.t("setup.press_key")
          end
        end
      end
    end

    def test_connection(menu)
      text = "#{I18n.t('setup.account.test_connection')}\n\n" \
             "#{I18n.t('setup.account.backup_configuration')}:"
      menu.choice(text) do
        result = Setup::ConnectionTester.new(account).test
        Kernel.puts result
        highline.ask I18n.t("setup.press_key")
      end
    end

    def toggle_mirror_mode(menu)
      menu_item = I18n.t("setup.account.toggle_mirror_mode")
      new_value = account.mirror_mode ? nil : true
      menu.choice(menu_item) do
        account.mirror_mode = new_value
      end
    end

    def modify_backup_path(menu)
      menu.choice(I18n.t("setup.account.modify_backup_path")) do
        Setup::BackupPath.new(account: account, config: config).run
      end
    end

    def toggle_folder_blacklist(menu)
      menu_item = I18n.t("setup.account.toggle_folder_blacklist")
      new_value = account.folder_blacklist ? nil : true
      menu.choice(menu_item) do
        account.folder_blacklist = new_value
      end
    end

    def choose_folders(menu)
      action_key = account.folder_blacklist ? "exclude_from_backups" : "include_in_backups"
      action = I18n.t("setup.account.#{action_key}")
      menu.choice(I18n.t("setup.account.choose_folders", action: action)) do
        Setup::FolderChooser.new(account).run
      end
    end

    def modify_multi_fetch_size(menu)
      menu.choice(I18n.t("setup.account.modify_multi_fetch_size")) do
        size = highline.ask(I18n.t("setup.account.size_prompt"))
        int = size.to_i
        account.multi_fetch_size = int if int.positive?
      end
    end

    def toggle_reset_seen_flags_after_fetch(menu)
      menu_item =
        if account.reset_seen_flags_after_fetch
          I18n.t("setup.account.dont_fix_unread_flags")
        else
          I18n.t("setup.account.fix_unread_flags")
        end
      new_value = account.reset_seen_flags_after_fetch ? nil : true
      menu.choice(menu_item) do
        account.reset_seen_flags_after_fetch = new_value
      end
    end

    def rotate_status(menu)
      current_status = account.status
      statuses = %w[active archived offline]
      current_index = statuses.index(current_status) || 0
      next_index = (current_index + 1) % statuses.length
      next_status = statuses[next_index]

      menu_item = I18n.t(
        "setup.account.change_status",
        current: current_status,
        next: next_status
      )
      following_section = I18n.t("setup.account.danger_area")
      text = "#{menu_item}\n\n#{following_section}:"
      menu.choice(text) do
        account.status = next_status
      end
    end

    def delete_account(menu)
      menu_item = I18n.t("setup.account.delete")
      following_section = I18n.t("setup.account.other_actions")
      text = "#{menu_item}\n\n#{following_section}:"
      menu.choice(text) do
        if highline.agree(I18n.t("setup.account.delete_confirm"))
          account.mark_for_deletion
          throw :done
        end
      end
    end

    def show_help(menu)
      menu.choice(I18n.t("setup.account.help")) do
        Kernel.puts I18n.t("setup.account.help_text")
        highline.ask I18n.t("setup.press_key")
      end
    end
  end
end
