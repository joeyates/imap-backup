require "highline"

module Imap::Backup
  module Configuration; end

  class Configuration::Setup
    class << self
      attr_accessor :highline
    end
    self.highline = HighLine.new

    def run
      Imap::Backup.setup_logging config
      catch :done do
        loop do
          system("clear")
          show_menu
        end
      end
    end

    private

    def show_menu
      self.class.highline.choose do |menu|
        menu.header = "Choose an action"
        account_items menu
        add_account_item menu
        toggle_logging_item menu
        menu.choice("save and exit") do
          config.save
          throw :done
        end
        menu.choice("exit without saving changes") do
          throw :done
        end
      end
    end

    def account_items(menu)
      config.accounts.each do |account|
        next if account[:delete]
        item = account[:username].clone
        item << " *" if account[:modified]
        menu.choice(item) do
          edit_account account[:username]
        end
      end
    end

    def add_account_item(menu)
      menu.choice("add account") do
        username = Configuration::Asker.email
        edit_account username
      end
    end

    def toggle_logging_item(menu)
      menu_item = config.debug? ? "stop logging" : "start logging"
      new_setting = !config.debug?
      menu.choice(menu_item) do
        config.debug = new_setting
        Imap::Backup.setup_logging config
      end
    end

    def config
      @config ||= Configuration::Store.new
    end

    def default_account_config(username)
      {
        username: username,
        password: "",
        local_path: File.join(config.path, username.tr("@", "_")),
        folders: []
      }
    end

    def edit_account(username)
      account = config.accounts.find { |a| a[:username] == username }
      if account.nil?
        account = default_account_config(username)
        config.accounts << account
      end
      Configuration::Account.new(
        config, account, Configuration::Setup.highline
      ).run
    end
  end
end
