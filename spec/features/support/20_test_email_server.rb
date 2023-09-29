require "net/imap"
require "retry_on_error"
require_relative "10_server_message_helpers"

class TestEmailServer
  include ServerMessageHelpers
  include RetryOnError

  REQUESTED_ATTRIBUTES = [BODY_ATTRIBUTE, "FLAGS"].freeze

  attr_reader :connection_parameters

  def initialize(**connection_parameters)
    @connection_parameters = connection_parameters
  end

  def imap
    @imap ||=
      begin
        connection = connection_parameters
        imap = Net::IMAP.new(
          connection[:server], connection[:connection_options]
        )
        imap.login(connection[:username], connection[:password])
        imap
      end
  end

  def reconnect
    disconnect
    imap
  end

  def disconnect
    return if !@imap

    if !imap.disconnected?
      begin
        imap.logout
      rescue EOFError
        # ignore occasional error when closing connection
      end
      imap.disconnect
    end

    @imap = nil
  end

  def root_folder
    root_info = imap.list("", "")[0]
    root_info.name
  end

  def folders
    retry_on_error(errors: [::IOError], limit: 2, on_error: -> { reconnect }) do
      imap.list(root_folder, "*")
    end
  end

  def create_folder(folder)
    return if folder_exists?(folder)

    imap.create(folder)
  end

  def delete_folder(folder)
    return if !folder_exists?(folder)

    # N.B. If we are deleting the currently selected folder
    # (previously selected via "select" or "examine"),
    # this command will cause a disconnect
    imap.delete folder
  end

  def folder_exists?(folder)
    examine(folder)
    true
  rescue StandardError
    false
  end

  def rename_folder(from, to)
    imap.rename(from, to)
  end

  def empty_folder(folder)
    imap.select(folder)
    uids = imap.uid_search(["ALL"]).sort
    imap.uid_store(uids, "+FLAGS", [:Deleted])
    imap.expunge
  end

  def send_email(folder, **options)
    flags = options[:flags]
    message = message_as_server_message(**options)
    imap.append(folder, message, flags, nil)
  end

  def send_multiple_emails(folder, count: 1000, batch: 100, **options)
    flags = options.delete(:flags)
    message = message_as_server_message(**options)
    literal = Net::IMAP::Literal.new(message)
    (1..count).each_slice(batch) do |items|
      args = []
      args.push(flags) if flags
      1.upto(items.count) do
        args.push(literal)
      end
      imap.__send__(:send_command, "APPEND", folder, *args)
    end
  end

  def delete_email(folder, uid)
    set_flags(folder, [uid], [:Deleted])
    imap.expunge
  end

  def fetch_email(folder, uid)
    examine folder

    fetch_data_items = imap.uid_fetch([uid.to_i], REQUESTED_ATTRIBUTES)
    return nil if fetch_data_items.nil?

    fetch_data_item = fetch_data_items[0]
    fetch_data_item.attr
  end

  def examine(folder)
    retry_on_error(errors: [::IOError], limit: 2, on_error: -> { reconnect }) do
      imap.examine(folder)
    end
  end

  def folder_uid_validity(folder)
    examine(folder)
    imap.responses["UIDVALIDITY"][0]
  end

  def folder_uids(folder)
    examine(folder)
    imap.uid_search(["ALL"]).sort
  end

  def folder_messages(folder)
    folder_uids(folder).map do |uid|
      fetch_email(folder, uid)
    end
  end

  def set_flags(folder, uids, flags)
    imap.select(folder)
    imap.uid_store(uids, "FLAGS", flags)
  end
end
