require "imap/backup/setup/helpers"

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
      modified = account.modified? ? "*" : ""

      multi_fetch_size = "\nmulti-fetch #{account.multi_fetch_size}" if account.multi_fetch_size > 1

      if account.connection_options
        escaped =
          JSON.generate(account.connection_options)
        connection_options =
          "\nconnection options  '#{escaped}'"
        space = " " * 12
      else
        connection_options = nil
        space = " " * 4
      end

      menu.header = <<~HEADER.chomp
        #{helpers.title_prefix} Account#{modified}

        email   #{space}#{account.username}
        password#{space}#{masked_password}
        path    #{space}#{account.local_path}
        folders #{space}#{folders.map { |f| f[:name] }.join(', ')}#{multi_fetch_size}
        server  #{space}#{account.server}#{connection_options}

        Choose an action
      HEADER
    end

    def modify_email(menu)
      menu.choice("modify email") do
        username = Setup::Asker.email(username)
        Kernel.puts "username: #{username}"
        other_accounts = config.accounts.reject { |a| a == account }
        others = other_accounts.map(&:username)
        Kernel.puts "others: #{others.inspect}"
        if others.include?(username)
          Kernel.puts(
            "There is already an account set up with that email address"
          )
        else
          account.username = username
          default = default_server(username)
          account.server = default if default && (account.server.nil? || (account.server == ""))
        end
      end
    end

    def modify_password(menu)
      menu.choice("modify password") do
        password = Setup::Asker.password

        account.password = password if !password.nil?
      end
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

    def modify_backup_path(menu)
      menu.choice("modify backup path") do
        account.local_path = Setup::Asker.backup_path(
          account.local_path, ->(path) { path_modification_validator(path) }
        )
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

    def folders
      account.folders || []
    end

    def masked_password
      if (account.password == "") || account.password.nil?
        "(unset)"
      else
        account.password.gsub(/./, "x")
      end
    end

    def default_server(username)
      provider = Email::Provider.for_address(username)

      if provider.is_a?(Email::Provider::Unknown)
        Kernel.puts "Can't decide provider for email address '#{username}'"
        return nil
      end

      provider.host
    end

    def helpers
      Setup::Helpers.new
    end
  end
end
