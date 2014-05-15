# encoding: utf-8

module Imap::Backup
  module Configuration; end

  class Configuration::FolderChooser
    def initialize(account)
      @account = account
    end

    def run
      begin
        @connection = Account::Connection.new(@account)
      rescue => e
        Imap::Backup.logger.warn 'Connection failed'
        Configuration::Setup.highline.ask 'Press a key '
        return
      end
      @folders = @connection.folders
      if @folders.nil?
        Imap::Backup.logger.warn 'Unable to get folder list'
        Configuration::Setup.highline.ask 'Press a key '
        return
      end
      loop do
        system('clear')
        Configuration::Setup.highline.choose do |menu|
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
