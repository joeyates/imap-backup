require "net/imap"
require "gmail_xoauth"

require "gmail/authenticator"

module Imap::Backup
  module Account; end

  class Account::Connection
    class InvalidGmailOauth2RefreshToken < StandardError; end

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
          root = provider_root
          mailbox_lists = imap.list(root, "*")

          if mailbox_lists.nil?
            message = "Unable to get folder list for account #{username}"
            Imap::Backup.logger.info message
            raise message
          end

          utf7_encoded = mailbox_lists.map(&:name)
          utf7_encoded.map { |n| Net::IMAP.decode_utf7(n) }
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
      imap
      each_folder do |folder, serializer|
        next if !folder.exist?

        Imap::Backup.logger.debug "[#{folder.name}] running backup"
        serializer.apply_uid_validity(folder.uid_validity)
        Downloader.new(folder, serializer).run
      end
    end

    def restore
      local_folders do |serializer, folder|
        restore_folder serializer, folder
      end
    end

    def disconnect
      imap.disconnect
    end

    def reconnect
      disconnect
      @imap = nil
    end

    def imap
      return @imap unless @imap.nil?

      options = provider_options
      Imap::Backup.logger.debug(
        "Creating IMAP instance: #{server}, options: #{options.inspect}"
      )
      @imap = Net::IMAP.new(server, options)
      if gmail? && Gmail::Authenticator.refresh_token?(password)
        authenticator = Gmail::Authenticator.new(email: username, token: password)
        credentials = authenticator.credentials
        raise InvalidGmailOauth2RefreshToken if !credentials

        Imap::Backup.logger.debug "Logging in with OAuth2 token: #{username}"
        @imap.authenticate("XOAUTH2", username, credentials.access_token)
      else
        Imap::Backup.logger.debug "Logging in: #{username}/#{masked_password}"
        @imap.login(username, password)
      end
      Imap::Backup.logger.debug "Login complete"
      @imap
    end

    def server
      return @server if @server
      return nil if provider.nil?

      @server = provider.host
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

    def gmail?
      server == Email::Provider::GMAIL_IMAP_SERVER
    end

    def local_folders
      glob = File.join(local_path, "**", "*.imap")
      base = Pathname.new(local_path)
      Pathname.glob(glob) do |path|
        name = path.relative_path_from(base).to_s[0..-6]
        serializer = Serializer::Mbox.new(local_path, name)
        folder = Account::Folder.new(self, name)
        yield serializer, folder
      end
    end

    def backup_folders
      @backup_folders ||=
        begin
          if @config_folders && @config_folders.any?
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

    # 6.3.8. LIST Command
    # An empty ("" string) mailbox name argument is a special request to
    # return the hierarchy delimiter and the root name of the name given
    # in the reference.
    def provider_root
      return @provider_root if @provider_root

      root_info = imap.list("", "")[0]
      @provider_root = root_info.name
    end
  end
end
