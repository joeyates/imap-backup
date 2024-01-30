require "thor"

require "imap/backup/cli/helpers"
require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Implements the CLI functions relating to configured online accounts
  class CLI::Remote < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "folders EMAIL [OPTIONS]", "List account folders"
    config_option
    format_option
    quiet_option
    verbose_option
    # Prints an account's folders
    # @return [void]
    def folders(email)
      Imap::Backup::Logger.setup_logging options
      folder_names = folder_names(email)
      case options[:format]
      when "json"
        json_format_names folder_names
      else
        list_names folder_names
      end
    end

    desc "capabilities EMAIL [OPTIONS]", "List server capabilities"
    long_desc <<~DESC
      Lists the IMAP capabilities supported by the IMAP server.
    DESC
    config_option
    format_option
    quiet_option
    verbose_option
    # Prints an account's IMAP capabilities
    # @return [void]
    def capabilities(email)
      Imap::Backup::Logger.setup_logging options
      config = load_config(**options)
      account = account(config, email)
      capabilities = account.capabilities
      Kernel.puts capabilities.join(", ")
    end

    desc "namespaces EMAIL [OPTIONS]", "List account namespaces"
    long_desc <<~DESC
      Lists namespaces defined for an email account.

      This command is useful in deciding the parameters for
      the `imap-backup migrate` and `imap-backup mirror` commands.
    DESC
    config_option
    format_option
    quiet_option
    verbose_option
    # Prints an account's IMAP namespaces
    # @return [void]
    def namespaces(email)
      Imap::Backup::Logger.setup_logging options
      config = load_config(**options)
      account = account(config, email)
      namespaces = account.namespaces
      case options[:format]
      when "json"
        json_format_namespaces namespaces
      else
        list_namespaces namespaces
      end
    end

    private

    def folder_names(email)
      config = load_config(**options)
      account = account(config, email)

      account.client.list
    end

    def json_format_names(names)
      list = names.map do |name|
        {name: name}
      end
      Kernel.puts list.to_json
    end

    def list_names(names)
      names.each do |name|
        Kernel.puts %("#{name}")
      end
    end

    def json_format_namespaces(namespaces)
      list = {
        personal: namespace_info(namespaces.personal.first),
        other: namespace_info(namespaces.other.first),
        shared: namespace_info(namespaces.shared.first)
      }
      Kernel.puts list.to_json
    end

    def list_namespaces(namespaces)
      Kernel.puts format(
        "%-10<name>s %-10<prefix>s %<delim>s",
        {name: "Name", prefix: "Prefix", delim: "Delimiter"}
      )
      list_namespace namespaces, :personal
      list_namespace namespaces, :other
      list_namespace namespaces, :shared
    end

    def list_namespace(namespaces, name)
      info = namespace_info(namespaces.send(name).first, quote: true)
      if info
        Kernel.puts format("%-10<name>s %-10<prefix>s %<delim>s", name: name, **info)
      else
        Kernel.puts format("%-10<name>s (Not defined)", name: name)
      end
    end

    def namespace_info(namespace, quote: false)
      return nil if !namespace

      {
        prefix: quote ? namespace.prefix.to_json : namespace.prefix,
        delim: quote ? namespace.delim.to_json : namespace.delim
      }
    end
  end
end
