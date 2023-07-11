module Imap::Backup
  class CLI::Stats < Thor
    include Thor::Actions
    include CLI::Helpers

    TEXT_COLUMNS = [
      {name: :folder, width: 20, alignment: :left},
      {name: :remote, width: 8, alignment: :right},
      {name: :both, width: 8, alignment: :right},
      {name: :local, width: 8, alignment: :right}
    ].freeze
    ALIGNMENT_FORMAT_SYMBOL = {left: "-", right: " "}.freeze

    attr_reader :email
    attr_reader :options

    def initialize(email, options)
      super([])
      @email = email
      @options = options
    end

    no_commands do
      def run
        case options[:format]
        when "json"
          Kernel.puts stats.to_json
        else
          format_text stats
        end
      end

      def stats
        config = load_config(**options)
        account = account(config, email)

        backup_folders = Account::Connection::BackupFolders.new(
          client: account.client, account: account
        ).run
        backup_folders.map do |folder|
          next if !folder.exist?

          serializer = Serializer.new(account.local_path, folder.name)
          local_uids = serializer.uids
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
end
