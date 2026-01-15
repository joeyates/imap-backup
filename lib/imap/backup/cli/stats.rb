require "thor"

require "imap/backup/account/backup_folders"
require "imap/backup/cli/helpers"
require "imap/backup/serializer"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Prints various statistics about an account and its backup
  class CLI::Stats < Thor
    include Thor::Actions
    include CLI::Helpers

    # @param email [String] the email address identifying the account to inspect
    # @param options [Hash] CLI options controlling output
    # @option opts [String] :config (nil) the path to the configuration file
    # @option opts [String] :erb_configuration (nil) the path to the ERB configuration file
    # @option opts [String] :format ("text") the output format, either "text" or "json"
    def initialize(email, options)
      super([])
      @email = email
      @options = options
    end

    # @!method run
    #   @return [void]
    no_commands do
      def run
        case options[:format]
        when "json"
          Kernel.puts stats.to_json
        else
          format_text stats
        end
      end
    end

    private

    TEXT_COLUMNS = [
      {name: :folder, width: 20, alignment: :left},
      {name: :remote, width: 8, alignment: :right},
      {name: :both, width: 8, alignment: :right},
      {name: :local, width: 8, alignment: :right}
    ].freeze
    ALIGNMENT_FORMAT_SYMBOL = {left: "-", right: " "}.freeze
    private_constant :TEXT_COLUMNS, :ALIGNMENT_FORMAT_SYMBOL

    attr_reader :email
    attr_reader :options

    def stats
      Logger.logger.debug("[Stats] loading configuration")
      config = load_config(**options)
      account = account(config, email)

      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      )
      backup_folders.map do |folder|
        next if !folder.exist?

        path = Serializer::Files::Path.new(
          base_path: account.local_path, folder_name: folder.name
        )
        serializer = Serializer.new(files_path: path)
        local_uids = serializer.uids
        Logger.logger.debug("[Stats] fetching email list for '#{folder.name}'")
        remote_uids = folder.uids
        {
          folder: folder.name,
          remote: (remote_uids - local_uids).count,
          both: (serializer.uids & folder.uids).count,
          local: (local_uids - remote_uids).count
        }
      end.compact
    end

    def format_text(stats)
      Kernel.puts text_header

      stats.each do |stat|
        columns = TEXT_COLUMNS.map do |column|
          symbol = ALIGNMENT_FORMAT_SYMBOL[column[:alignment]]
          count = stat[column[:name]]
          format("%#{symbol}#{column[:width]}s", count)
        end.join("|")

        Kernel.puts columns
      end
    end

    def text_header
      titles = TEXT_COLUMNS.map do |column|
        format("%-#{column[:width]}s", column[:name])
      end.join("|")

      underline = TEXT_COLUMNS.map do |column|
        "-" * column[:width]
      end.join("|")

      "#{titles}\n#{underline}"
    end
  end
end
