require "imap/backup/configuration"

module Imap; end
module Imap::Backup; end
class Imap::Backup::Setup; end

class Imap::Backup::Setup::GlobalOptions
  # Allows changing the globally configured download strategy
  class DownloadStrategyChooser
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
          create_menu
        end
      end
    end

    private

    attr_reader :config

    def create_menu
      strategies = Imap::Backup::Configuration::DOWNLOAD_STRATEGIES
      highline.choose do |menu|
        menu.header = I18n.t("setup.global_options.download_strategy_chooser.title")

        current_marker = I18n.t("setup.global_options.download_strategy_chooser.current_marker")
        strategies.each do |strategy|
          current = strategy == config.download_strategy ? current_marker : ""
          description = I18n.t("configuration.download_strategy.#{strategy}.short")
          topic = "#{description}#{current}"
          menu.choice(topic) do
            config.download_strategy = strategy
          end
        end
        show_help menu
        menu.choice(I18n.t("setup.global_options.download_strategy_chooser.return_to_main_menu")) do
          throw :done
        end
        menu.hidden("quit") { throw :done }
      end
    end

    def show_help(menu)
      menu.choice(I18n.t("setup.global_options.download_strategy_chooser.help")) do
        Kernel.puts I18n.t("setup.global_options.download_strategy_chooser.help_text")
        highline.ask I18n.t("setup.global_options.download_strategy_chooser.press_key")
      end
    end

    def highline
      Imap::Backup::Setup.highline
    end
  end
end
