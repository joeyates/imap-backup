module ServerMessageHelpers
  BODY_ATTRIBUTE = "BODY[]".freeze

  def message_as_server_message(from:, subject:, body:, **_options)
    <<~MESSAGE.gsub("\n", "\r\n")
      From: #{from}
      Subject: #{subject}

      #{body}

    MESSAGE
  end

  def server_message_to_body(message)
    message[BODY_ATTRIBUTE]
  end
end

class TestEmailServer
  include ServerMessageHelpers

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
    # Reconnect if necessary to avoid '#<IOError: closed stream>'
    reconnect
    imap.list(root_folder, "*")
  end

  def create_folder(folder)
    # Reconnect if necessary to avoid '#<IOError: closed stream>'
    reconnect

    return if folder_exists?(folder)

    imap.create(folder)
  end

  def delete_folder(folder)
    # Reconnect if necessary to avoid '#<IOError: closed stream>'
    reconnect

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
    imap.examine(folder)
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

module EmailServerHelpers
  def test_server_connection_parameters
    {
      server: ENV.fetch("DOCKER_HOST_IMAP", "localhost"),
      username: "address@example.com",
      password: "pass",
      local_path: File.join(File.expand_path("~/.imap-backup"), "address_example.com"),
      connection_options: {
        port: ENV.fetch("DOCKER_PORT_IMAP", "8993").to_i,
        ssl: {verify_mode: 0}
      }
    }
  end

  def other_server_connection_parameters
    {
      server: ENV.fetch("DOCKER_HOST_OTHER_IMAP", "localhost"),
      username: "email@other.org",
      password: "pass",
      local_path: File.join(File.expand_path("~/.imap-backup"), "email_other.org"),
      connection_options: {
        port: ENV.fetch("DOCKER_PORT_OTHER_IMAP", "9993").to_i,
        ssl: {verify_mode: 0}
      }
    }
  end

  def test_server
    @test_server ||= TestEmailServer.new(**test_server_connection_parameters)
  end

  def other_server
    @other_server ||= TestEmailServer.new(**other_server_connection_parameters)
  end
end

RSpec.configure do |config|
  config.include ServerMessageHelpers, type: :aruba
  config.include EmailServerHelpers, type: :aruba
end
