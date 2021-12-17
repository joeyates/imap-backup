require "imap/backup/client/apple_mail"
require "imap/backup/client/default"

require "retry_on_error"

module Imap::Backup
  module Account; end

  class Account::Connection
    include RetryOnError

    LOGIN_RETRY_CLASSES = [EOFError, Errno::ECONNRESET, SocketError].freeze

    attr_reader :connection_options
    attr_reader :local_path
    attr_reader :password
    attr_reader :username

    def initialize(options)
      @username = options[:username]
      @password = options[:password]
      @local_path = options[:local_path]
      @config_folders = options[:folders]
      @server = options[:server]
      @connection_options = options[:connection_options] || {}
      @folders = nil
      create_account_folder
    end

    def folders
      @folders ||=
        begin
          folders = client.list

          if folders.empty?
            message = "Unable to get folder list for account #{username}"
            Imap::Backup.logger.info message
            raise message
          end

          folders
        end
    end

    def status
      backup_folders.map do |backup_folder|
        f = Account::Folder.new(self, backup_folder[:name])
        s = Serializer::Mbox.new(local_path, backup_folder[:name])
        {name: backup_folder[:name], local: s.uids, remote: f.uids}
      end
    end

    def run_backup
      Imap::Backup.logger.debug "Running backup of account: #{username}"
      # start the connection so we get logging messages in the right order
      client
      each_folder do |folder, serializer|
        next if !folder.exist?

        Imap::Backup.logger.debug "[#{folder.name}] running backup"
        serializer.apply_uid_validity(folder.uid_validity)
        begin
          Downloader.new(folder, serializer).run
        rescue Net::IMAP::ByeResponseError
          reconnect
          retry
        end
      end
    end

    def local_folders
      return enum_for(:local_folders) if !block_given?

      glob = File.join(local_path, "**", "*.imap")
      base = Pathname.new(local_path)
      Pathname.glob(glob) do |path|
        name = path.relative_path_from(base).to_s[0..-6]
        serializer = Serializer::Mbox.new(local_path, name)
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
    end

    def reconnect
      disconnect
      @client = nil
    end

    def client
      @client ||=
        retry_on_error(errors: LOGIN_RETRY_CLASSES) do
          options = provider_options
          Imap::Backup.logger.debug(
            "Creating IMAP instance: #{server}, options: #{options.inspect}"
          )
          client =
            if provider.is_a?(Email::Provider::AppleMail)
              Client::AppleMail.new(server, options)
            else
              Client::Default.new(server, options)
            end
          Imap::Backup.logger.debug "Logging in: #{username}/#{masked_password}"
          client.login(username, password)
          Imap::Backup.logger.debug "Login complete"
          client
        end
    end

    def server
      @server ||= provider.host
    end

    private

    def each_folder
      backup_folders.each do |backup_folder|
        folder = Account::Folder.new(self, backup_folder[:name])
        serializer = Serializer::Mbox.new(local_path, backup_folder[:name])
        yield folder, serializer
      end
    end

    def restore_folder(serializer, folder)
      existing_uids = folder.uids
      if existing_uids.any?
        Imap::Backup.logger.debug(
          "There's already a '#{folder.name}' folder with emails"
        )
        new_name = serializer.apply_uid_validity(folder.uid_validity)
        old_name = serializer.folder
        if new_name
          Imap::Backup.logger.debug(
            "Backup '#{old_name}' renamed and restored to '#{new_name}'"
          )
          new_serializer = Serializer::Mbox.new(local_path, new_name)
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

    def create_account_folder
      Utils.make_folder(
        File.dirname(local_path),
        File.basename(local_path),
        Serializer::DIRECTORY_PERMISSIONS
      )
    end

    def masked_password
      password.gsub(/./, "x")
    end

    def backup_folders
      @backup_folders ||=
        begin
          if @config_folders&.any?
            @config_folders
          else
            folders.map { |name| {name: name} }
          end
        end
    end

    def provider
      @provider ||= Email::Provider.for_address(username)
    end

    def provider_options
      provider.options.merge(connection_options)
    end
  end
end
