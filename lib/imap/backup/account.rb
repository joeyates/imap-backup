require "json"

require "imap/backup/account/client_factory"
require "imap/backup/account/restore"

module Imap; end

module Imap::Backup
  # Contains the attributes relating to an email account.
  class Account
    # By default, the backup process fetches one email at a time
    DEFAULT_MULTI_FETCH_SIZE = 1

    # The username of the account (usually the same as the email address)
    # @return [String]
    attr_reader :username
    # @return [String] password of the Account
    attr_reader :password
    # @return [String] the path where backups will be saved
    attr_reader :local_path
    # @overload folders
    #   The list of folders that have been configured for the Account
    #   @see #folder_blacklist how this list is interpreted.
    #   @return [Array<String>, void]
    # @overload folders=(value)
    #   Sets the folders attribute and marks it as modified, storing the original value
    #   @param value [Array<String>] a list of folders
    #   @return [void]
    attr_reader :folders
    # Indicates whether the configured folders are a whitelist or a blacklist.
    # When true, any folders attribute will be taken as a list of folders to
    # skip when running backups.
    # When false, the folders attribute is used as the list of folders to backup.
    # If no folders are configured, all folders on the server are backed up
    # irrespective of the folder_blacklist setting
    # @return [Boolean]
    attr_reader :folder_blacklist
    # Should all emails be backed up progressively, or should emails
    # which are deleted from the server be deleted locally?
    # @return [Boolean]
    attr_reader :mirror_mode
    # The address of the IMAP server
    # @return [String]
    attr_reader :server
    # Extra options to be passed to the IMAP server when connecting
    # @return [Hash, void]
    attr_reader :connection_options
    # The name of the download strategy to adopt during backups
    # @return [String]
    attr_accessor :download_strategy
    # Should 'Seen' flags be cached before fetchiong emails and
    # rewritten to the server afterwards?
    #
    # Some IMAP providers, notably Apple Mail, set the '\Seen' flag
    # on emails when they are fetched. By setting `:reset_seen_flags_after_fetch`,
    # a workaround is activated which checks which emails are 'unseen' before
    # and after the fetch, and removes the '\Seen' flag from those which have changed.
    # As this check is susceptible to 'race conditions', i.e. when a different
    # client sets the '\Seen' flag while imap-backup is fetching, it is best
    # to only use it when required (i.e. for IMAP providers which always
    # mark messages as '\Seen' when accessed).
    # @return [Boolean]
    attr_reader :reset_seen_flags_after_fetch

    def initialize(options)
      @username = options[:username]
      @password = options[:password]
      @local_path = options[:local_path]
      @folders = options[:folders]
      @folder_blacklist = options[:folder_blacklist]
      @mirror_mode = options[:mirror_mode]
      @server = options[:server]
      @connection_options = options[:connection_options]
      @download_strategy = options[:download_strategy]
      @multi_fetch_size_orignal = options[:multi_fetch_size]
      @reset_seen_flags_after_fetch = options[:reset_seen_flags_after_fetch]
      @client = nil
      @changes = {}
      @marked_for_deletion = false
    end

    # Initializes a client for the account's IMAP server
    #
    # @return [Account::Client::Default] the client
    def client
      @client ||= Account::ClientFactory.new(account: self).run
    end

    # Returns the namespaces configured for the account on the IMAP server
    #
    # @return [Array<String>] the namespaces
    def namespaces
      client.namespace
    end

    # Returns the capabilites of the IMAP server
    #
    # @return [Array<String>] the capabilities
    def capabilities
      client.capability
    end

    # Restore the local backup to the server
    #
    # @return [void]
    def restore
      restore = Account::Restore.new(account: self)
      restore.run
    end

    # Indicates whether the account has been configured, and is ready
    # to be used
    #
    # @return [Boolean]
    def valid?
      username && password ? true : false
    end

    def modified?
      changes.any?
    end

    # Resets the store of changes, indicating that the current state is the saved state
    # @return [void]
    def clear_changes
      @changes = {}
    end

    # Sets a flag indicating the Account should be excluded from the next save operation
    #
    # @return [void]
    def mark_for_deletion
      @marked_for_deletion = true
    end

    # @return [Boolean] whether the account has been flagged for deletion during setup
    def marked_for_deletion?
      @marked_for_deletion
    end

    # @return [Hash] all Account data for serialization
    def to_h
      h = {username: @username, password: @password}
      h[:local_path] = @local_path if @local_path
      h[:folders] = @folders if @folders
      h[:folder_blacklist] = true if @folder_blacklist
      h[:mirror_mode] = true if @mirror_mode
      h[:server] = @server if @server
      h[:connection_options] = @connection_options if @connection_options
      h[:multi_fetch_size] = multi_fetch_size
      if @reset_seen_flags_after_fetch
        h[:reset_seen_flags_after_fetch] = @reset_seen_flags_after_fetch
      end
      h
    end

    # Sets the username attribute and marks it as modified, storing the original value
    #
    # @return [void]
    def username=(value)
      update(:username, value)
    end

    # Sets the password attribute and marks it as modified, storing the original value
    #
    # @return [void]
    def password=(value)
      update(:password, value)
    end

    # Sets the local_path attribute and marks it as modified, storing the original value
    #
    # @return [void]
    def local_path=(value)
      update(:local_path, value)
    end

    # @return [void]
    def folders=(value)
      raise "folders must be an Array" if !value.is_a?(Array)

      update(:folders, value)
    end

    # @return [void]
    def folder_blacklist=(value)
      update(:folder_blacklist, value)
    end

    # @return [void]
    def mirror_mode=(value)
      update(:mirror_mode, value)
    end

    # @return [void]
    def server=(value)
      update(:server, value)
    end

    # @return [void]
    def connection_options=(value)
      parsed =
        if value == ""
          nil
        else
          JSON.parse(value, symbolize_names: true)
        end
      update(:connection_options, parsed)
    end

    # The number of emails to fetch from the IMAP server at a time
    #
    # @return [Integer]
    def multi_fetch_size
      @multi_fetch_size ||= begin
        int = @multi_fetch_size_orignal.to_i
        if int.positive?
          int
        else
          DEFAULT_MULTI_FETCH_SIZE
        end
      end
    end

    # Sets the multi_fetch_size attribute and marks it as modified, storing the original value.
    # If the supplied value is not a positive integer, uses {DEFAULT_MULTI_FETCH_SIZE}
    #
    # @return [void]
    def multi_fetch_size=(value)
      parsed = value.to_i
      parsed = DEFAULT_MULTI_FETCH_SIZE if !parsed.positive?
      update(:multi_fetch_size, parsed)
    end

    # @return [void]
    def reset_seen_flags_after_fetch=(value)
      update(:reset_seen_flags_after_fetch, value)
    end

    private

    attr_reader :changes

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
        changes[field] = {from: current, to: value} if value != current
      end

      @client = nil
      instance_variable_set(key, value)
    end
  end
end
