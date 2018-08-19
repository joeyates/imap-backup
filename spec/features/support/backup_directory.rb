module BackupDirectoryHelpers
  def message_as_mbox_entry(options)
    from = fixture("connection")[:username]
    subject = options[:subject]
    body = options[:body]
    body_and_headers = <<-EOT.gsub("\n", "\r\n")
From: #{from}
Subject: #{subject}

#{body}
    EOT

    "From #{from}\n#{body_and_headers}\n"
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
