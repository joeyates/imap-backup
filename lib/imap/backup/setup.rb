require "highline"
require "i18n"

require "imap/backup/account"
require "imap/backup/email/provider"
require "imap/backup/setup/account"
require "imap/backup/setup/asker"
require "imap/backup/setup/global_options"
require "imap/backup/setup/helpers"

module Imap; end

module Imap::Backup
  # Interactively updates the application's configuration file
  class Setup
    class << self
      # @return [Highline]
      attr_accessor :highline
    end
    self.highline = HighLine.new

    # @param config [Configuration] the application configuration
    def initialize(config:)
      @config = config
    end

    # Shows the menu
    # @return [void]
    def run
      catch :done do
        loop do
          Kernel.system("clear")
          show_menu
        end
      end
    end

    private

    attr_accessor :config

    def show_menu
      self.class.highline.choose do |menu|
        menu.header = <<~MENU.chomp
          #{helpers.title_prefix} #{I18n.t('setup.main_menu.title')}

          #{I18n.t('setup.choose_action')}
        MENU
        account_items menu
        add_account_item menu
        modify_global_options menu
        show_help menu
        if config.modified?
          menu.choice(I18n.t("setup.main_menu.save_and_exit")) do
            config.save
            throw :done
          end
          menu.choice(I18n.t("setup.main_menu.exit_without_saving")) { throw :done }
        else
          menu.choice(I18n.t("setup.main_menu.quit")) { throw :done }
          menu.hidden("quit") { throw :done }
        end
      end
    end

    def account_items(menu)
      config.accounts.each do |account|
        next if account.marked_for_deletion?

        item = account.username.clone
        item << " *" if account.modified?
        menu.choice(item) do
          edit_account account.username
        end
      end
    end

    def add_account_item(menu)
      menu.choice(I18n.t("setup.main_menu.add_account")) do
        username = Asker.email
        edit_account username
      end
    end

    def modify_global_options(menu)
      changed = config.download_strategy_modified? ? " *" : ""
      menu.choice("#{I18n.t('setup.main_menu.modify_global_options')}#{changed}") do
        GlobalOptions.new(config: config).run
      end
    end

    def show_help(menu)
      menu.choice(I18n.t("setup.main_menu.help")) do
        Kernel.puts I18n.t("setup.main_menu.help_text")
        self.class.highline.ask I18n.t("setup.press_key")
      end
    end

    def default_account_config(username)
      Imap::Backup::Account.new(
        username: username,
        password: "",
        local_path: nil,
        folders: []
      ).tap do |a|
        provider = Imap::Backup::Email::Provider.for_address(username)
        a.server = provider.host if provider.host
        a.reset_seen_flags_after_fetch = true if provider.sets_seen_flags_on_fetch?
      end
    end

    def edit_account(username)
      account = config.accounts.find { |a| a.username == username }
      if account.nil?
        account = default_account_config(username)
        config.accounts << account
      end
      Account.new(config, account, Setup.highline).run
    end

    def helpers
      Helpers.new
    end
  end
end
