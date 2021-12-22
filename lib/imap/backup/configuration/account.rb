module Imap::Backup
  module Configuration; end

  Configuration::Account = Struct.new(:store, :account, :highline) do
    def initialize(store, account, highline)
      super
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
        modify_server menu
        modify_connection_options menu
        test_connection menu
        delete_account menu
        menu.choice("return to main menu") { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def header(menu)
      connection_options =
        if account.connection_options
          escaped =
            JSON.generate(account.connection_options).
            gsub('"', '\"')
          "\n  connection options: #{escaped}"
        end
      menu.header = <<~HEADER
        Account:
          email:    #{account.username}
          password: #{masked_password}
          path:     #{account.local_path}
          folders:  #{folders.map { |f| f[:name] }.join(', ')}
          server:   #{account.server}#{connection_options}
      HEADER
    end

    def modify_email(menu)
      menu.choice("modify email") do
        username = Configuration::Asker.email(username)
        Kernel.puts "username: #{username}"
        other_accounts = store.accounts.reject { |a| a == account }
        others = other_accounts.map { |a| a.username }
        Kernel.puts "others: #{others.inspect}"
        if others.include?(username)
          Kernel.puts(
            "There is already an account set up with that email address"
          )
        else
          account.username = username
          # rubocop:disable Style/IfUnlessModifier
          default = default_server(username)
          if default && (account.server.nil? || (account.server == ""))
            account.server = default
          end
          # rubocop:enable Style/IfUnlessModifier
        end
      end
    end

    def modify_password(menu)
      menu.choice("modify password") do
        password = Configuration::Asker.password

        account.password = password if !password.nil?
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
        account.connection_options = connection_options if !connection_options.nil?
      end
    end

    def path_modification_validator(path)
      same = store.accounts.find do |a|
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
        existing = account.local_path.clone
        account.local_path = Configuration::Asker.backup_path(
          account.local_path, ->(path) { path_modification_validator(path) }
        )
      end
    end

    def choose_folders(menu)
      menu.choice("choose backup folders") do
        Configuration::FolderChooser.new(account).run
      end
    end

    def test_connection(menu)
      menu.choice("test connection") do
        result = Configuration::ConnectionTester.test(account)
        Kernel.puts result
        highline.ask "Press a key "
      end
    end

    def delete_account(menu)
      menu.choice("delete") do
        if highline.agree("Are you sure? (y/n) ")
          account.mark_for_deletion!
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
  end
end
