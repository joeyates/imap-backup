module EmailServerHelpers
  REQUESTED_ATTRIBUTES = ["RFC822", "FLAGS", "INTERNALDATE"]

  def send_email(folder, options)
    from = options[:from] || "address@example.org"
    subject = options[:subject]
    body = options[:body]
    message = <<-EOT
From: #{from}
Subject: #{subject}

#{body}
    EOT

    imap.append(folder, message, nil, nil)
  end

  def delete_emails(folder)
    imap.select(folder)
    uids = imap.uid_search(["ALL"]).sort
    imap.store(1 .. uids.size, "+FLAGS", [:Deleted])
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
  config.include EmailServerHelpers, type: :feature
end
