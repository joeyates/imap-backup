require "thor"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  class CLI::Direct < Thor
    attr_reader :options
    attr_reader :password

    def initialize(options)
      super([])
      @options = options
    end

    no_commands do
      def run
      end

      def handle_password_options!
        plain = options[:password]
        env = options[:password_environment_variable]
        file = options[:password_file]
        case [plain, env, file]
        when [nil, nil, nil]
          raise Thor::RequiredArgumentMissingError,
            "Supply one of the --password... parameters"
        when [plain, nil, nil]
          @password = plain
        when [nil, env, nil]
          @password = ENV.fetch(env)
        when [nil, nil, file]
          @password = File.read(file).gsub(/\n$/, "")
        else
          raise ArgumentError, "Supply only one of the --password... parameters"
        end
      end
    end
  end
end

