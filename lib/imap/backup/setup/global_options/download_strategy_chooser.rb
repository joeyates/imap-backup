require "imap/backup/configuration"

module Imap; end
module Imap::Backup; end
class Imap::Backup::Setup; end

class Imap::Backup::Setup::GlobalOptions
  # Allows changing the globally configured download strategy
  class DownloadStrategyChooser
    def initialize(config:)
      @config = config
    end

    # Shows the menu
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
        menu.header = "Choose a Download Strategy"

        strategies.each do |s|
          current = s[:key] == config.download_strategy ? " <- current" : ""
          topic = "#{s[:description]}#{current}"
          menu.choice(topic) do
            config.download_strategy = s[:key]
          end
        end
        show_help menu
        menu.choice("(q) return to main menu") { throw :done }
        menu.hidden("quit") { throw :done }
      end
    end

    def show_help(menu)
      menu.choice("help") do
        Kernel.puts <<~HELP
          This setting changes how often data is written to disk during backups.

          imap-backup uses two files per folder, a .mbox file with the actual
          messages and a .imap file with metadata like message lengths and their
          offsets within the .mbox file.

          # write straight to disk

          With this setting, each message and its metadata are written to disk
          as they are downloaded.

          This choice uses least memory and so is suitable for backing up onto
          devices with limited memory, like Raspberry Pis.

          # delay writing metadata

          This is the default setting.

          Here, messages (which are potentially very large) are appended to the
          .mbox file as they are received, but the metadata is only written to
          the .imap file once all the folder's messages have been downloaded.

          This choice uses a little more memory than the previous setting, but
          is **much** faster for large folders (potentially >30 times for
          folders with >100k messages) and is less wearing on the disk.

          # Other Performance Settings

          Another configuration which affects backup performance is the
          `multi_fetch_size` account-level setting.

        HELP
        highline.ask "Press a key "
      end
    end

    def highline
      Imap::Backup::Setup.highline
    end
  end
end
