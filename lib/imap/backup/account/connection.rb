require "net/imap"

module Imap::Backup
  module Account; end

  class Account::Connection
    attr_reader :connection_options
    attr_reader :local_path
    attr_reader :password
    attr_reader :username

    def initialize(options)
      @username, @password = options[:username], options[:password]
      @local_path = options[:local_path]
      @backup_folders = options[:folders]
      @server = options[:server]
      @connection_options = options[:connection_options] || {}
      @folders = nil
      create_account_folder
    end

    def folders
      @folders ||=
        begin
          root = provider_root
          @folders = imap.list(root, "*")
          if @folders.nil?
            Imap::Backup.logger.warn(
              "Unable to get folder list for account #{username}"
            )
          end
          @folders
        end
    end

    def status
      backup_folders.map do |folder|
        f = Account::Folder.new(self, folder[:name])
        s = Serializer::Mbox.new(local_path, folder[:name])
        {name: folder[:name], local: s.uids, remote: f.uids}
      end
    end

    def run_backup
      Imap::Backup.logger.debug "Running backup of account: #{username}"
      # start the connection so we get logging messages in the right order
      imap
      each_folder do |folder, serializer|
        Imap::Backup.logger.debug "[#{folder.name}] running backup"
        serializer.set_uid_validity(folder.uid_validity)
        Downloader.new(folder, serializer).run
      end
    end

    def restore
      local_folders do |serializer, folder|
        exists = folder.exist?
        if exists
          new_name = serializer.set_uid_validity(folder.uid_validity)
          old_name = serializer.folder
          if new_name
            Imap::Backup.logger.debug "Backup '#{old_name}' renamed and restored to '#{new_name}'"
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
      Imap::Backup.logger.debug "Logging in: #{username}/#{masked_password}"
      @imap.login(username, password)
      Imap::Backup.logger.debug "Login complete"
      @imap
    end

    private

    def each_folder
      backup_folders.each do |folder_info|
        folder = Account::Folder.new(self, folder_info[:name])
        serializer = Serializer::Mbox.new(local_path, folder_info[:name])
        yield folder, serializer
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
      return @backup_folders if @backup_folders && (@backup_folders.size > 0)
      (folders || []).map { |f| {name: f.name} }
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

    def provider
      @provider ||= Email::Provider.for_address(username)
    end

    def server
      return @server if @server
      return nil if provider.nil?
      @server = provider.host
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
