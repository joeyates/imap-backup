require "imap/backup/configuration"
require "imap/backup/setup/global_options/download_strategy_chooser"

module Imap; end

module Imap::Backup
  class Setup; end

  class Setup::GlobalOptions
    attr_reader :config

    def initialize(config:)
      @config = config
    end

    def run
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
          Global Options

          These settings affect all accounts.

          Choose an action
        MENU
        change_download_strategy menu
        menu.choice("(q) return to main menu") { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def change_download_strategy(menu)
      strategies = Imap::Backup::Configuration::DOWNLOAD_STRATEGIES
      current = strategies.find { |s| s[:key] == config.download_strategy }
      changed = config.download_strategy_modified? ? " *" : ""
      menu.choice("change download strategy (currently: '#{current[:description]}')#{changed}") do
        DownloadStrategyChooser.new(config: config).run
      end
    end

    def highline
      Imap::Backup::Setup.highline
    end
  end
end
