# encoding: utf-8

module Imap
  module Backup
    module Configuration

      class Account

        def initialize(store, account)
          @store, @account = store, account
        end

        def run
          loop do
            Setup.highline.choose do |menu|
              password =
                if @account[:password] == ''
                 '(unset)'
                else
                  @account[:password].gsub(/./, 'x')
                end
              menu.header = <<EOT
Account:
  email:    #{@account[:username]}
  path:     #{@account[:local_path]}
  folders:  #{@account[:folders].map { |f| f[:name] }.join(', ')}
  password: #{password}
EOT
              menu.choice('modify email') do
                username = Asker.email(username)
                others   = @store.data[:accounts].select { |a| a != @account}.map { |a| a[:username] }
                if others.include?(username)
                  puts 'There is already an account set up with that email address'
                else
                  @account[:username] = username
                end
              end
              menu.choice('modify password') do
                password = Asker.password
                if ! password.nil?
                  @account[:password] = password
                end
              end
              menu.choice('modify backup path') do
                validator = lambda do |p|
                  same = @store.data[:accounts].find do |a|
                    a[:username] != @account[:username] && a[:local_path] == p
                  end
                  if same
                    puts "The path '#{p}' is used to backup the account '#{same[:username]}'"
                    false
                  else
                    true
                  end
                end
                @account[:local_path] = Asker.backup_path(@account[:local_path], validator)
              end
              menu.choice('choose backup folders') do
                FolderChooser.new(@account).run
              end
              menu.choice 'test authentication' do
                result = ConnectionTester.test(@account)
                puts result 
                Setup.highline.ask 'Press a key '
              end
              menu.choice(:delete) do
                if Setup.highline.agree("Are you sure? (y/n) ")
                  @store.data[:accounts].reject! { |a| a[:username] == @account[:username] }
                  return
                end
              end
              menu.choice('return to main menu') do
                return
              end
              menu.hidden('quit') do
                return
              end
            end
          end
        end

      end
    end
  end
end

