require "thor"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  class CLI::Direct < Thor
    no_commands do
      def run
      end

      def check_password_options!
      end
    end
  end
end

