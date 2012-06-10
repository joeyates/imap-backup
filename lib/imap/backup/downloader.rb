require 'json'

module Imap
  module Backup
    class Downloader

      include Imap::Backup::Utils

      def initialize(account, folder)
        @account, @folder = account, folder

        check_permissions(@account.local_path, 0700)
      end

      def status
        {:local => local_uids, :remote => @account.uids(@folder)}
      end

      def run
        make_folder(@account.local_path, @folder, 'g-wrx,o-wrx')
        @account.each_uid(@folder) do |uid|
          message_filename = "#{destination_path}/%012u.json" % uid.to_i
          next if File.exist?(message_filename)

          message = @account.fetch(uid)

          File.open(message_filename, 'w') { |f| f.write message.to_json }
          FileUtils.chmod 0600, message_filename
        end
      end

      private

      def destination_path
        File.join(@account.local_path, @folder)
      end

      def local_uids
        return [] if ! File.exist?(destination_path)

        d = Dir.open(destination_path)
        d.map do |file|
          file[/^0*(\d+).json$/, 1]
        end.compact
      end

      def remote_uids
      end

    end
  end
end

