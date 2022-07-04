module EmailServerHelpers
  REQUESTED_ATTRIBUTES = ["BODY[]"].freeze
  DEFAULT_EMAIL = "address@example.org".freeze

  def send_email(folder, options)
    message = message_as_server_message(options)
    imap.append(folder, message, nil, nil)
  end

  def message_as_server_message(options)
    from = options[:from] || DEFAULT_EMAIL
    subject = options[:subject]
    body = options[:body]

    <<~MESSAGE.gsub("\n", "\r\n")
      From: #{from}
      Subject: #{subject}

      #{body}

    MESSAGE
  end

  def server_messages(folder)
    server_uids(folder).map do |uid|
      server_fetch_email(folder, uid)
    end
  end

  def server_message_to_body(message)
    message["BODY[]"]
  end

  def server_fetch_email(folder, uid)
    examine folder

    fetch_data_items = imap.uid_fetch([uid.to_i], REQUESTED_ATTRIBUTES)
    return nil if fetch_data_items.nil?

    fetch_data_item = fetch_data_items[0]
    fetch_data_item.attr
  end

  def server_empty_folder(folder)
    imap.select(folder)
    uids = imap.uid_search(["ALL"]).sort
    imap.store(1..uids.size, "+FLAGS", [:Deleted])
    imap.expunge
  end

  def examine(folder)
    imap.examine(folder)
  end

  def server_uids(folder)
    examine(folder)
    imap.uid_search(["ALL"]).sort
  end

  def server_uid_validity(folder)
    examine(folder)
    imap.responses["UIDVALIDITY"][0]
  end

  def server_folders
    imap.list(server_root_folder, "*")
  end

  def server_root_folder
    root_info = imap.list("", "")[0]
    root_info.name
  end

  def server_folder_exists?(folder)
    examine(folder)
    true
  rescue StandardError
    false
  end

  def server_create_folder(folder)
    return if server_folder_exists?(folder)

    imap.create(folder)
  end

  def server_rename_folder(from, to)
    imap.rename(from, to)
  end

  def server_delete_folder(folder)
    # Reconnect if necessary to avoid '#<IOError: closed stream>'
    reconnect_imap

    return if !server_folder_exists?(folder)

    # N.B. If we are deleting the currently selected folder
    # (previously selected via "select" or "examine"),
    # this command will cause a disconnect
    imap.delete folder
  end

  def imap
    @imap ||=
      begin
        connection = fixture("connection")
        imap = Net::IMAP.new(
          connection[:server], connection[:connection_options]
        )
        imap.login(connection[:username], connection[:password])
        imap
      end
  end

  def reconnect_imap
    disconnect_imap
    imap
  end

  def disconnect_imap
    return if !@imap

    if !imap.disconnected?
      imap.disconnect
    end

    @imap = nil
  end
end

RSpec.configure do |config|
  config.include EmailServerHelpers, type: :aruba
  config.include EmailServerHelpers, type: :feature
end
