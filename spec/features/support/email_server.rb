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

  def delete_emails(folder)
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
    imap.list(root, "*")
  end

  def root
    root_info = imap.list("", "")[0]
    root_info.name
  end

  def server_create_folder(folder)
    imap.create(folder)
    imap.disconnect
    @imap = nil
  end

  def server_rename_folder(from, to)
    imap.rename(from, to)
    imap.disconnect
    @imap = nil
  end

  def server_delete_folder(folder)
    imap.delete folder
    imap.disconnect
  rescue StandardError => e
    puts e.to_s
  ensure
    @imap = nil
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
end

RSpec.configure do |config|
  config.include EmailServerHelpers, type: :aruba
  config.include EmailServerHelpers, type: :feature
end
