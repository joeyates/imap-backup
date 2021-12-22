module Imap::Backup
  class Account
    attr_reader :username
    attr_reader :password
    attr_reader :local_path
    attr_reader :folders
    attr_reader :server
    attr_reader :connection_options
    attr_reader :changes
    attr_reader :marked_for_deletion

    def initialize(options)
      @username = options[:username]
      @password = options[:password]
      @local_path = options[:local_path]
      @folders = options[:folders]
      @server = options[:server]
      @connection_options = options[:connection_options]
      @changes = {}
      @marked_for_deletion = false
    end

    def valid?
      username && password
    end

    def modified?
      changes.any?
    end

    def clear_changes!
      @changes = {}
    end

    def mark_for_deletion!
      @marked_for_deletion = true
    end

    def marked_for_deletion?
      @marked_for_deletion
    end

    def to_h
      h = {
        username: @username,
        password: @password,
      }
      h[:local_path] = @local_path if @local_path
      h[:folders] = @folders if @folders
      h[:server] = @server if @server
      h[:connection_options] = @connection_options if @connection_options
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

    private

    def update(field, value)
      if changes[field]
        change = changes[field]
        changes.delete(field) if change[:from] == value
      end
      set_field!(field, value)
    end

    def set_field!(field, value)
      key = :"@#{field}"
      current = instance_variable_get(key)
      changes[field] = {from: current, to: value}
      instance_variable_set(key, value)
    end
  end
end
