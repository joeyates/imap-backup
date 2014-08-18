require 'net/imap'

module Imap::Backup
  module Account; end

  class Account::Connection
    attr_reader :username
    attr_reader :local_path

    def initialize(options)
      @username, @password = options[:username], options[:password]
      @local_path = options[:local_path]
      @backup_folders = options[:folders]
      @server = options[:server]
      @folders = nil
    end

    def folders
      return @folders if @folders
      root = provider_root
      @folders = imap.list(root, '*')
      if @folders.nil?
        Imap::Backup.logger.warn "Unable to get folder list for account #{username}, (root '#{root}'"
      end
      @folders
    end

    def status
      backup_folders.map do |folder|
        f = Account::Folder.new(self, folder[:name])
        s = Serializer::Directory.new(local_path, folder[:name])
        {:name => folder[:name], :local => s.uids, :remote => f.uids}
      end
    end

    def run_backup
      Imap::Backup.logger.debug "Running backup of account: #{username}"
      # start the connection so we get logging messages in the right order
      imap
      backup_folders.each do |folder|
        Imap::Backup.logger.debug "[#{folder[:name]}] running backup"
        f = Account::Folder.new(self, folder[:name])
        s = Serializer::Mbox.new(local_path, folder[:name])
        d = Downloader.new(f, s)
        d.run
      end
    end

    def disconnect
      imap.disconnect
    end

    def imap
      return @imap unless @imap.nil?
      options = provider_options
      Imap::Backup.logger.debug "Creating IMAP instance: #{server}, options: #{options.inspect}"
      @imap = Net::IMAP.new(server, options)
      Imap::Backup.logger.debug "Logging in: #{username}/#{masked_password}"
      @imap.login(username, password)
      Imap::Backup.logger.debug "Login complete"
      @imap
    end

    private

    def password
      @password
    end

    def masked_password
      password.gsub(/./, 'x')
    end
    
    def backup_folders
      return @backup_folders if @backup_folders and @backup_folders.size > 0
      (folders || []).map { |f| {:name => f.name} }
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
      provider.options
    end

    def provider_root
      provider.root
    end
  end
end
