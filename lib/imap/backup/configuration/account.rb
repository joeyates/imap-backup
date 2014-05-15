# encoding: utf-8

module Imap::Backup
  module Configuration; end

  class Configuration::Account < Struct.new(:store, :account, :highline)
    def initialize(store, account, highline)
      super
    end

    def run
      catch :done do
        loop do
          system('clear')
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
        modify_server menu
        modify_backup_path menu
        choose_folders menu
        test_connection menu
        delete_account menu
        menu.choice('return to main menu') { throw :done }
        menu.hidden('quit') { throw :done }
      end
    end

    def header(menu)
      menu.header = <<-EOT
Account:
  email:    #{account[:username]}
  server:   #{account[:server]}
  path:     #{account[:local_path]}
  folders:  #{folders.map { |f| f[:name] }.join(', ')}
  password: #{masked_password}
      EOT
    end

    def modify_email(menu)
      menu.choice('modify email') do
        username = Configuration::Asker.email(username)
        puts "username: #{username}"
        others   = store.data[:accounts].select { |a| a != account}.map { |a| a[:username] }
        puts "others: #{others.inspect}"
        if others.include?(username)
          puts 'There is already an account set up with that email address'
        else
          account[:username] = username
          if account[:server].nil? or account[:server] == ''
            account[:server] = default_server(username)
          end
        end
      end
    end

    def modify_password(menu)
      menu.choice('modify password') do
        password = Configuration::Asker.password
        if ! password.nil?
          account[:password] = password
        end
      end
    end

    def modify_server(menu)
      menu.choice('modify server') do
        server = highline.ask('server: ')
        if ! server.nil?
          account[:server] = server
        end
      end
    end

    def modify_backup_path(menu)
      menu.choice('modify backup path') do
        validator = lambda do |p|
          same = store.data[:accounts].find do |a|
            a[:username] != account[:username] && a[:local_path] == p
          end
          if same
            puts "The path '#{p}' is used to backup the account '#{same[:username]}'"
            false
          else
            true
          end
        end
        account[:local_path] = Configuration::Asker.backup_path(account[:local_path], validator)
      end
    end

    def choose_folders(menu)
      menu.choice('choose backup folders') do
        Configuration::FolderChooser.new(account).run
      end
    end

    def test_connection(menu)
      menu.choice('test connection') do
        result = Configuration::ConnectionTester.test(account)
        puts result
        highline.ask 'Press a key '
      end
    end

    def delete_account(menu)
      menu.choice('delete') do
        if highline.agree("Are you sure? (y/n) ")
          store.data[:accounts].reject! { |a| a[:username] == account[:username] }
          throw :done
        end
      end
    end

    def folders
      account[:folders] || []
    end

    def masked_password
      if account[:password] == '' or account[:password].nil?
        '(unset)'
      else
        account[:password].gsub(/./, 'x')
      end
    end

    def default_server(username)
      case username
      when /@gmail\.com/
        'imap.gmail.com'
      when /@fastmail\.fm/
        'mail.messagingengine.com'
      end
    end
  end
end
