require 'json'

module Imap
  module Backup
    class Downloader

      include Imap::Backup::Utils

      def initialize(account, folder)
        @account, @folder = account, folder

        check_permissions(@account.local_path, 0700)
      end

      def run
        make_folder(@account.local_path, @folder, 'g-wrx,o-wrx')
        destination_path = File.join(@account.local_path, @folder)
        @account.each_uid(@folder) do |uid|
          message_filename = "#{destination_path}/%012u.json" % uid.to_i
          next if File.exist?(message_filename)

          message = @account.fetch(uid)

          File.open(message_filename, 'w') { |f| f.write message.to_json }
          FileUtils.chmod 0600, message_filename
        end
      end

    end
  end
end

