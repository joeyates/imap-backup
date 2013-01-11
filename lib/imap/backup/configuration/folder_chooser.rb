# encoding: utf-8

module Imap
  module Backup
    module Configuration
      class FolderChooser
        def initialize(account)
          @account = account
        end

        def run
          begin
            @connection = Imap::Backup::Account::Connection.new(@account)
          rescue => e
            puts 'Connection failed'
            Setup.highline.ask 'Press a key '
            return
          end
          @folders = @connection.folders
          loop do
            system('clear')
            Setup.highline.choose do |menu|
              menu.header = 'Add/remove folders'
              menu.index = :number
              @folders.each do |folder|
                name  = folder.name
                found = @account[:folders].find { |f| f[:name] == name }
                mark  =
                  if found
                    '+'
                  else
                    '-'
                  end
                menu.choice("#{mark} #{name}") do
                  if found
                    @account[:folders].reject! { |f| f[:name] == name }
                  else
                    @account[:folders] << { :name => name }
                  end
                end
              end
              menu.choice('return to the account menu') do
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

