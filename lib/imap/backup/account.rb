module Imap::Backup
  class Account
    DEFAULT_MULTI_FETCH_SIZE = 1

    attr_reader :username
    attr_reader :password
    attr_reader :local_path
    attr_reader :folders
    attr_reader :server
    attr_reader :connection_options
    attr_reader :changes

    def initialize(options)
      @username = options[:username]
      @password = options[:password]
      @local_path = options[:local_path]
      @folders = options[:folders]
      @server = options[:server]
      @connection_options = options[:connection_options]
      @multi_fetch_size = options[:multi_fetch_size]
      @changes = {}
      @marked_for_deletion = false
    end

    def connection
      Account::Connection.new(self)
    end

    def valid?
      username && password ? true : false
    end

    def modified?
      changes.any?
    end

    def clear_changes
      @changes = {}
    end

    def mark_for_deletion
      @marked_for_deletion = true
    end

    def marked_for_deletion?
      @marked_for_deletion
    end

    def to_h
      h = {username: @username, password: @password}
      h[:local_path] = @local_path if @local_path
      h[:folders] = @folders if @folders
      h[:server] = @server if @server
      h[:connection_options] = @connection_options if @connection_options
      h[:multi_fetch_size] = multi_fetch_size if @multi_fetch_size
      h
    end

    def username=(value)
      update(:username, value)
    end

    def password=(value)
      update(:password, value)
    end

    def local_path=(value)
      update(:local_path, value)
    end

    def folders=(value)
      raise "folders must be an Array" if !value.is_a?(Array)

      update(:folders, value)
    end

    def server=(value)
      update(:server, value)
    end

    def connection_options=(value)
      parsed = JSON.parse(value)
      update(:connection_options, parsed)
    end

    def multi_fetch_size
      int = @multi_fetch_size.to_i
      if int.positive?
        int
      else
        DEFAULT_MULTI_FETCH_SIZE
      end
    end

    def multi_fetch_size=(value)
      parsed = value.to_i
      parsed = DEFAULT_MULTI_FETCH_SIZE if !parsed.positive?
      update(:multi_fetch_size, parsed)
    end

    private

    def update(field, value)
      key = :"@#{field}"
      if changes[field]
        change = changes[field]
        if change[:from] == value
          changes.delete(field)
        else
          change[:to] = value
        end
      else
        current = instance_variable_get(key)
        changes[field] = {from: current, to: value}
      end

      instance_variable_set(key, value)
    end
  end
end
