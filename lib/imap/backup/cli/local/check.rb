module Imap; end

module Imap::Backup
  class CLI; end
  class CLI::Local < Thor; end

  class CLI::Local::Check
    include CLI::Helpers

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      results = requested_accounts(config).map do |account|
        serialized_folders = Account::SerializedFolders.new(account: account)
        folder_results = serialized_folders.map do |serializer, _folder|
          serializer.check_integrity!
          {name: serializer.folder, result: "OK"}
        rescue Serializer::FolderIntegrityError => e
          message = e.to_s
          if options[:delete_corrupt]
            serializer.delete
            message << " and has been deleted"
          end

          {
            name: serializer.folder,
            result: message
          }
        end
        {account: account.username, folders: folder_results}
      end

      case options[:format]
      when "json"
        print_check_results_as_json(results)
      else
        print_check_results_as_text(results)
      end
    end

    def print_check_results_as_json(results)
      Kernel.puts results.to_json
    end

    def print_check_results_as_text(results)
      results.each do |account_results|
        Kernel.puts "Account: #{account_results[:account]}"
        account_results[:folders].each do |folder_results|
          Kernel.puts "\t#{folder_results[:name]}: #{folder_results[:result]}"
        end
      end
    end

    def config
      @config ||= load_config(**options)
    end
  end
end
