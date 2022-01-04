require "imap/backup/setup/helpers"

module Imap::Backup
  class Setup; end

  class Setup::FolderChooser
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def run
      if connection.nil?
        Imap::Backup::Logger.logger.warn "Connection failed"
        highline.ask "Press a key "
        return
      end

      if imap_folders.nil?
        Imap::Backup::Logger.logger.warn "Unable to get folder list"
        highline.ask "Press a key "
        return
      end

      remove_missing

      catch :done do
        loop do
          Kernel.system("clear")
          show_menu
        end
      end
    end

    private

    def show_menu
      highline.choose do |menu|
        menu.header = <<~MENU.chomp
          #{helpers.title_prefix} Add/remove folders

          Select a folder (toggles)
        MENU
        menu.index = :number
        add_folders menu
        menu.choice("(q) return to the account menu") { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def add_folders(menu)
      imap_folders.each do |folder|
        mark = selected?(folder) ? "+" : "-"
        menu.choice("#{mark} #{folder}") do
          toggle_selection folder
        end
      end
    end

    def selected?(folder_name)
      config_folders = account.folders
      return false if config_folders.nil?

      config_folders.find { |f| f[:name] == folder_name }
    end

    def remove_missing
      removed = []
      config_folders = []
      account.folders.each do |f|
        found = imap_folders.find { |folder| folder == f[:name] }
        if found
          config_folders << f
        else
          removed << f[:name]
        end
      end

      return if removed.empty?

      account.folders = config_folders

      Kernel.puts <<~MESSAGE
        The following folders have been removed: #{removed.join(', ')}
      MESSAGE

      highline.ask "Press a key "
    end

    def toggle_selection(folder_name)
      if selected?(folder_name)
        new_list = account.folders.select { |f| f[:name] != folder_name }
        account.folders = new_list
      else
        existing = account.folders || []
        account.folders = existing + [{name: folder_name}]
      end
    end

    def connection
      @connection ||= Account::Connection.new(account)
    rescue StandardError
      nil
    end

    def imap_folders
      @imap_folders ||= connection.folder_names
    end

    def highline
      Setup.highline
    end

    def helpers
      Setup::Helpers.new
    end
  end
end
