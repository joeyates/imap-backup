require "imap/backup/setup/account/header"
require "imap/backup/setup/backup_path"
require "imap/backup/setup/email"

module Imap::Backup
  class Setup; end

  class Setup::Account
    attr_reader :account
    attr_reader :config
    attr_reader :highline

    def initialize(config, account, highline)
      @account = account
      @config = config
      @highline = highline
    end

    def run
      catch :done do
        loop do
          Kernel.system("clear")
          create_menu
        end
      end
    end

    private

    def create_menu
      highline.choose do |menu|
        header menu
        modify_email menu
        modify_password menu
        modify_backup_path menu
        choose_folders menu
        modify_multi_fetch_size menu
        modify_server menu
        modify_connection_options menu
        test_connection menu
        delete_account menu
        menu.choice("(q) return to main menu") { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def header(menu)
      Setup::Account::Header.new(menu: menu, account: account).run
    end

    def modify_email(menu)
      menu.choice("modify email") do
        Setup::Email.new(account: account, config: config).run
      end
    end

    def modify_password(menu)
      menu.choice("modify password") do
        password = Setup::Asker.password

        account.password = password if !password.nil?
      end
    end

    def modify_backup_path(menu)
      menu.choice("modify backup path") do
        Setup::BackupPath.new(account: account, config: config).run
      end
    end

    def choose_folders(menu)
      menu.choice("choose backup folders") do
        Setup::FolderChooser.new(account).run
      end
    end

    def modify_multi_fetch_size(menu)
      menu.choice("modify multi-fetch size (number of emails to fetch at a time)") do
        size = highline.ask("size: ")
        int = size.to_i
        account.multi_fetch_size = int if int.positive?
      end
    end

    def modify_server(menu)
      menu.choice("modify server") do
        server = highline.ask("server: ")
        account.server = server if !server.nil?
      end
    end

    def modify_connection_options(menu)
      menu.choice("modify connection options") do
        connection_options = highline.ask("connections options (as JSON): ")
        if !connection_options.nil?
          begin
            account.connection_options = connection_options
          rescue JSON::ParserError
            Kernel.puts "Malformed JSON, please try again"
            highline.ask "Press a key "
          end
        end
      end
    end

    def test_connection(menu)
      menu.choice("test connection") do
        result = Setup::ConnectionTester.new(account).test
        Kernel.puts result
        highline.ask "Press a key "
      end
    end

    def delete_account(menu)
      menu.choice("delete") do
        if highline.agree("Are you sure? (y/n) ")
          account.mark_for_deletion
          throw :done
        end
      end
    end
  end
end
