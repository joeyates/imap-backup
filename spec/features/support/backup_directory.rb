module BackupDirectoryHelpers
  def message_as_mbox_entry(options)
    from = fixture("connection")[:username]
    subject = options[:subject]
    body = options[:body]
    body_and_headers = <<~BODY
      From: #{from}
      Subject: #{subject}

      #{body}
    BODY

    "From #{from}\n#{body_and_headers}\n"
  end

  def imap_data(uid_validity, uids)
    {
      version: 2,
      uid_validity: uid_validity,
      uids: uids
    }
  end

  def mbox_content(name)
    File.read(mbox_path(name))
  end

  def mbox_path(name)
    File.join(local_backup_path, name + ".mbox")
  end

  def imap_path(name)
    File.join(local_backup_path, name + ".imap")
  end

  def imap_content(name)
    File.read(imap_path(name))
  end

  def imap_parsed(name)
    JSON.parse(imap_content(name), symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.include BackupDirectoryHelpers, type: :feature
end
