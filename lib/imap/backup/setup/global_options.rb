require "imap/backup/configuration"
require "imap/backup/setup/global_options/download_strategy_chooser"

module Imap; end

module Imap::Backup
  class Setup; end

  # Shows the menu of global options
  class Setup::GlobalOptions
    # @param config [Configuration] the application configuration
    def initialize(config:)
      @config = config
    end

    # Shows the menu
    # @return [void]
    def run
      catch :done do
        loop do
          Kernel.system("clear")
          show_menu
        end
      end
    end

    private

    attr_reader :config

    def show_menu
      highline.choose do |menu|
        menu.header = <<~MENU.chomp
          #{I18n.t('setup.global_options.title')}

          #{I18n.t('setup.global_options.description')}

          #{I18n.t('setup.global_options.choose_action')}
        MENU
        change_download_strategy menu
        menu.choice(I18n.t("setup.global_options.return_to_main_menu")) { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def change_download_strategy(menu)
      strategies = Imap::Backup::Configuration::DOWNLOAD_STRATEGIES
      current = strategies.find { |s| s[:key] == config.download_strategy }
      changed = config.download_strategy_modified? ? " *" : ""
      menu.choice(I18n.t("setup.global_options.change_download_strategy",
                         current: current[:description]) + changed) do
        DownloadStrategyChooser.new(config: config).run
      end
    end

    def highline
      Imap::Backup::Setup.highline
    end
  end
end
