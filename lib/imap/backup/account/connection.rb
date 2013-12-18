require 'net/imap'

module Imap::Backup::Account
  class Connection
    attr_reader :username, :local_path, :backup_folders, :server

    def initialize(options)
      @username, @password = options[:username], options[:password]
      @local_path, @backup_folders = options[:local_path], options[:folders]
      @server = options[:server] || host_for(username)
    end

    def folders
      root = root_for(username)
      imap.list(root, '*')
    end

    def status
      backup_folders.map do |folder|
        f = Imap::Backup::Account::Folder.new(self, folder[:name])
        s = Imap::Backup::Serializer::Directory.new(local_path, folder[:name])
        {:name => folder[:name], :local => s.uids, :remote => f.uids}
      end
    end

    def run_backup
      backup_folders.each do |folder|
        f = Imap::Backup::Account::Folder.new(self, folder[:name])
        s = Imap::Backup::Serializer::Mbox.new(local_path, folder[:name])
        d = Imap::Backup::Downloader.new(f, s)
        d.run
      end
    end

    def disconnect
      imap.disconnect
    end

    def imap
      return @imap unless @imap.nil?
      options = options_for(username)
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
      end
    end

    def options_for(username)
      case username
      when /@gmail\.com/
        {:port => 993, :ssl => true}
      when /@fastmail\.fm/
        {:port => 993, :ssl => true}
      end
    end
  end
end
