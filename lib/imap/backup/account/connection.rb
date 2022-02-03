require "imap/backup/client/apple_mail"
require "imap/backup/client/default"

require "retry_on_error"

module Imap::Backup
  class Account; end

  class Account::Connection
    include RetryOnError

    LOGIN_RETRY_CLASSES = [EOFError, Errno::ECONNRESET, SocketError].freeze

    attr_reader :account

    def initialize(account)
      @account = account
      reset
    end

    # TODO: Make this private once the 'folders' command
    # has been removed.
    def folder_names
      @folder_names ||=
        begin
          folder_names = client.list

          if folder_names.empty?
            message = "Unable to get folder list for account #{account.username}"
            Imap::Backup::Logger.logger.info message
            raise message
          end

          folder_names
        end
    end

    def backup_folders
      @backup_folders ||=
        begin
          names =
            if account.folders&.any?
              account.folders.map { |af| af[:name] }
            else
              folder_names
            end

          names.map do |name|
            Account::Folder.new(self, name)
          end
        end
    end

    def status
      ensure_account_folder
      backup_folders.map do |folder|
        s = Serializer::Mbox.new(account.local_path, folder.name)
        {name: folder.name, local: s.uids, remote: folder.uids}
      end
    end

    def run_backup
      Imap::Backup::Logger.logger.debug "Running backup of account: #{account.username}"
      # start the connection so we get logging messages in the right order
      client
      ensure_account_folder
      each_folder do |folder, serializer|
        next if !folder.exist?

        Imap::Backup::Logger.logger.debug "[#{folder.name}] running backup"
        serializer.apply_uid_validity(folder.uid_validity)
        begin
          Downloader.new(
            folder, serializer, block_size: config.download_block_size
          ).run
        rescue Net::IMAP::ByeResponseError
          reconnect
          retry
        end
      end
    end

    def local_folders
      return enum_for(:local_folders) if !block_given?

      ensure_account_folder
      glob = File.join(account.local_path, "**", "*.imap")
      base = Pathname.new(account.local_path)
      Pathname.glob(glob) do |path|
        name = path.relative_path_from(base).to_s[0..-6]
        serializer = Serializer::Mbox.new(account.local_path, name)
        folder = Account::Folder.new(self, name)
        yield serializer, folder
      end
    end

    def restore
      local_folders do |serializer, folder|
        restore_folder serializer, folder
      end
    end

    def disconnect
      client.disconnect if @client
      reset
    end

    def reconnect
      disconnect
    end

    def reset
      @backup_folders = nil
      @client = nil
      @config = nil
      @folder_names = nil
      @provider = nil
      @server = nil
    end

    def client
      @client ||=
        retry_on_error(errors: LOGIN_RETRY_CLASSES) do
          options = provider_options
          Imap::Backup::Logger.logger.debug(
            "Creating IMAP instance: #{server}, options: #{options.inspect}"
          )
          client =
            if provider.is_a?(Email::Provider::AppleMail)
              Client::AppleMail.new(server, options)
            else
              Client::Default.new(server, options)
            end
          Imap::Backup::Logger.logger.debug "Logging in: #{account.username}/#{masked_password}"
          client.login(account.username, account.password)
          Imap::Backup::Logger.logger.debug "Login complete"
          client
        end
    end

    def server
      @server ||= account.server || provider.host
    end

    private

    def each_folder
      backup_folders.each do |folder|
        serializer = Serializer::Mbox.new(account.local_path, folder.name)
        yield folder, serializer
      end
    end

    def restore_folder(serializer, folder)
      existing_uids = folder.uids
      if existing_uids.any?
        Imap::Backup::Logger.logger.debug(
          "There's already a '#{folder.name}' folder with emails"
        )
        new_name = serializer.apply_uid_validity(folder.uid_validity)
        old_name = serializer.folder
        if new_name
          Imap::Backup::Logger.logger.debug(
            "Backup '#{old_name}' renamed and restored to '#{new_name}'"
          )
          new_serializer = Serializer::Mbox.new(account.local_path, new_name)
          new_folder = Account::Folder.new(self, new_name)
          new_folder.create
          new_serializer.force_uid_validity(new_folder.uid_validity)
          Uploader.new(new_folder, new_serializer).run
        else
          Uploader.new(folder, serializer).run
        end
      else
        folder.create
        serializer.force_uid_validity(folder.uid_validity)
        Uploader.new(folder, serializer).run
      end
    end

    def ensure_account_folder
      Utils.make_folder(
        File.dirname(account.local_path),
        File.basename(account.local_path),
        Serializer::DIRECTORY_PERMISSIONS
      )
    end

    def masked_password
      account.password.gsub(/./, "x")
    end

    def provider
      @provider ||= Email::Provider.for_address(account.username)
    end

    def provider_options
      provider.options.merge(account.connection_options || {})
    end

    def config
      @config ||= Configuration.new
    end
  end
end
