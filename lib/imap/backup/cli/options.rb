require "thor"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Defines option methods for CLI classes
  class CLI::Options
    attr_reader :base

    # Options common to many commands
    OPTIONS = [
      {
        name: "accounts",
        parameters: {
          type: :string, aliases: ["-a"],
          desc: "a comma-separated list of accounts (defaults to all configured accounts)"
        }
      },
      {
        name: "config",
        parameters: {
          type: :string, aliases: ["-c"],
          desc: "supply the configuration file path (default: ~/.imap-backup/config.json)"
        }
      },
      {
        name: "format",
        parameters: {
          type: :string, desc: "the output type, 'text' for plain text or 'json'", aliases: ["-f"]
        }
      },
      {
        name: "quiet",
        parameters: {
          type: :boolean, desc: "silence all output", aliases: ["-q"]
        }
      },
      {
        name: "refresh",
        parameters: {
          type: :boolean, aliases: ["-r"],
          desc: "in the default 'keep all emails' mode, " \
                "updates flags for messages that are already downloaded"
        }
      },
      {
        name: "verbose",
        parameters: {
          type: :boolean, aliases: ["-v"], repeatable: true,
          desc: "increase the amount of logging. " \
                "Without this option, the program gives minimal output. " \
                "Using this option once gives more detailed output. " \
                "Whereas, using this option twice also shows all IMAP network calls"
        }
      }
    ].freeze

    def initialize(base:)
      @base = base
    end

    def define_options
      OPTIONS.each do |option|
        base.singleton_class.class_eval do
          define_method("#{option[:name]}_option") do
            method_option(option[:name], **option[:parameters])
          end
        end
      end
    end
  end
end
