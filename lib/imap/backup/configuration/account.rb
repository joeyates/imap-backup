# encoding: utf-8

module Imap
  module Backup
    module Configuration
      class Account
        attr_reader :store, :account, :highline

        def initialize(store, account, highline)
          @store, @account, @highline = store, account, highline
        end

        def run
          catch :done do
            loop do
              system('clear')
              highline.choose do |menu|
                menu.header = <<EOT
Account:
  email:    #{account[:username]}
  server:   #{account[:server]}
  path:     #{account[:local_path]}
  folders:  #{folders.map { |f| f[:name] }.join(', ')}
  password: #{masked_password}
EOT

                menu.choice('modify email') do
                  username = Asker.email(username)
                  puts "username: #{username}"
                  others   = @store.data[:accounts].select { |a| a != @account}.map { |a| a[:username] }
                  puts "others: #{others.inspect}"
                  if others.include?(username)
                    puts 'There is already an account set up with that email address'
                  else
                    @account[:username] = username
                    @account[:server] ||= default_server(username)
                  end
                end

                menu.choice('modify password') do
                  password = Asker.password
                  if ! password.nil?
                    @account[:password] = password
                  end
                end

                menu.choice('modify server') do
                  server = highline.ask('server: ')
                  if ! server.nil?
                    @account[:server] = server
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
                  highline.ask 'Press a key '
                end

                menu.choice 'delete' do
                  if highline.agree("Are you sure? (y/n) ")
                    @store.data[:accounts].reject! { |a| a[:username] == @account[:username] }
                    throw :done
                  end
                end

                menu.choice 'return to main menu' do
                  throw :done
                end

                menu.hidden('quit') do
                  throw :done
                end
              end
            end
          end
        end

        private

        def folders
          @account[:folders] || []
        end

        def masked_password
          if @account[:password] == '' or @account[:password].nil?
            '(unset)'
          else
            @account[:password].gsub(/./, 'x')
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
  end
end

