module Imap::Backup
  module Configuration; end

  class Configuration::FolderChooser
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def run
      if connection.nil?
        Imap::Backup.logger.warn "Connection failed"
        highline.ask "Press a key "
        return
      end

      if folders.nil?
        Imap::Backup.logger.warn "Unable to get folder list"
        highline.ask "Press a key "
        return
      end

      catch :done do
        loop do
          system("clear")
          show_menu
        end
      end
    end

    private

    def show_menu
      highline.choose do |menu|
        menu.header = "Add/remove folders"
        menu.index = :number
        add_folders menu
        menu.choice("return to the account menu") { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def add_folders(menu)
      folders.each do |folder|
        name = folder.name
        mark = is_selected?(name) ? "+" : "-"
        menu.choice("#{mark} #{name}") do
          toggle_selection name
        end
      end
    end

    def is_selected?(folder_name)
      backup_folders = account[:folders]
      return false if backup_folders.nil?
      backup_folders.find { |f| f[:name] == folder_name }
    end

    def toggle_selection(folder_name)
      if is_selected?(folder_name)
        changed = account[:folders].reject! { |f| f[:name] == folder_name }
        account[:modified] = true if changed
      else
        account[:folders] ||= []
        account[:folders] << {name: folder_name}
        account[:modified] = true
      end
    end

    def connection
      @connection ||= Account::Connection.new(account)
    rescue
      nil
    end

    def folders
      @folders ||= connection.folders
    end

    def highline
      Configuration::Setup.highline
    end
  end
end
