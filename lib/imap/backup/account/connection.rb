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
      root = root_for(username)
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
      backup_folders.each do |folder|
        f = Account::Folder.new(self, folder[:name])
        s = Serializer::Mbox.new(local_path, folder[:name])
        d = Downloader.new(f, s)
        d.run
      end
    end

    def disconnect
      imap.disconnect
    end

    def server
      @server ||= host_for(username)
    end

    def imap
      return @imap unless @imap.nil?
      options = options_for(server)
      Imap::Backup.logger.debug "Creating IMAP instance: #{server}, options: #{options.inspect}"
      @imap = Net::IMAP.new(server, options)
      Imap::Backup.logger.debug "Logging in: #{username}/#{masked_password}"
      @imap.login(username, password)
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

    def host_for(username)
      case username
      when /@gmail\.com/
        'imap.gmail.com'
      when /@fastmail\.fm/
        'mail.messagingengine.com'
      end
    end

    def root_for(username)
      case username
      when /@gmail\.com/
        '/'
      when /@fastmail\.fm/
        'INBOX'
      else
        '/'
      end
    end

    def options_for(server)
      case server
      when 'imap.gmail.com'
        {:port => 993, :ssl => true}
      when 'mail.messagingengine.com'
        {:port => 993, :ssl => true}
      else
        {:port => 993, :ssl => true}
      end
    end
  end
end
