module ServerMessageHelpers
  BODY_ATTRIBUTE = "BODY[]".freeze

  def message_as_server_message(from:, subject:, body:, **options)
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
    imap.list(root_folder, "*")
  end

  def create_folder(folder)
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

  def send_email(folder, options)
    message = message_as_server_message(**options)
    imap.append(folder, message, nil, nil)
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
end

module EmailServerHelpers
  def test_server_connection_parameters
    {
      server: 'localhost',
      username: 'address@example.com',
      password: 'pass',
      connection_options: {
        port: 8993,
        ssl: {verify_mode: 0}
      }
    }
  end

  def other_server_connection_parameters
    {
      server: 'localhost',
      username: 'email@other.org',
      password: 'pass',
      connection_options: {
        port: 9993,
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
