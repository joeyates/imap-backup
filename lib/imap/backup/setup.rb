require "highline"

require "email/provider"
require "imap/backup/account"
require "imap/backup/setup/global_options"
require "imap/backup/setup/helpers"

module Imap; end

module Imap::Backup
  class Setup
    class << self
      attr_accessor :highline
    end
    self.highline = HighLine.new

    attr_accessor :config

    def initialize(config:)
      @config = config
    end

    def run
      catch :done do
        loop do
          Kernel.system("clear")
          show_menu
        end
      end
    end

    private

    def show_menu
      self.class.highline.choose do |menu|
        menu.header = <<~MENU.chomp
          #{helpers.title_prefix} Main Menu

          Choose an action
        MENU
        account_items menu
        add_account_item menu
        modify_global_options menu
        if config.modified?
          menu.choice("save and exit") do
            config.save
            throw :done
          end
          menu.choice("exit without saving changes") { throw :done }
        else
          menu.choice("(q) quit") { throw :done }
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
      menu.choice("add account") do
        username = Asker.email
        edit_account username
      end
    end

    def modify_global_options(menu)
      changed = config.modified? ? " *" : ""
      menu.choice("modify global options#{changed}") do
        GlobalOptions.new(config: config, highline: Setup.highline).run
      end
    end

    def default_account_config(username)
      Imap::Backup::Account.new(
        username: username,
        password: "",
        folders: []
      ).tap do |a|
        provider = ::Email::Provider.for_address(username)
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
