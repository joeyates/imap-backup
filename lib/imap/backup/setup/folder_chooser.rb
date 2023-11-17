require "imap/backup/setup/helpers"

module Imap; end

module Imap::Backup
  class Setup; end

  class Setup::FolderChooser
    def initialize(account)
      @account = account
    end

    def run
      if client.nil?
        highline.ask "Press a key "
        return
      end

      if folder_names.empty?
        Logger.logger.warn "Unable to get folder list"
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

    attr_reader :account

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
      folder_names.each do |folder|
        mark = selected?(folder) ? "+" : "-"
        menu.choice("#{mark} #{folder}") do
          toggle_selection folder
        end
      end
    end

    def selected?(folder_name)
      account_folders.find { |f| f == folder_name }
    end

    def remove_missing
      removed = []
      config_folders = []
      account_folders.each do |f|
        found = folder_names.find { |folder| folder == f }
        if found
          config_folders << f
        else
          removed << f
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
      new_list =
        if selected?(folder_name)
          account_folders.reject { |f| f == folder_name }
        else
          account_folders + [folder_name]
        end
      account.folders = new_list
    end

    def client
      @client ||= account.client
    rescue StandardError
      Logger.logger.warn "Connection failed"
      nil
    end

    def folder_names
      @folder_names ||= client.list
    end

    def highline
      Setup.highline
    end

    def helpers
      Setup::Helpers.new
    end

    def account_folders
      account.folders || []
    end
  end
end
