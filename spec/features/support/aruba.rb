require "aruba/rspec"

require_relative "backup_directory"

Aruba.configure do |config|
  config.home_directory = File.expand_path("./tmp/home")
  config.allow_absolute_paths = true
end

module ConfigurationHelpers
  def config_path
    File.expand_path("~/.imap-backup")
  end

  def create_config(accounts:, debug: false)
    pathname = File.join(config_path, "config.json")
    save_data = {
      version: Imap::Backup::Configuration::VERSION,
      accounts: accounts,
      debug: debug
    }
    FileUtils.mkdir_p config_path
    File.open(pathname, "w") { |f| f.write(JSON.pretty_generate(save_data)) }
    FileUtils.chmod(0o600, pathname)
  end
end

module StoreHelpers
  def store_email(
    email:, folder:,
    uid: 1,
    from: "sender@example.com",
    subject: "The Subject",
    body: "body"
  )
    account = config.accounts.find { |a| a.username == email }
    raise "Account not found" if !account
    FileUtils.mkdir_p account.local_path
    store = Imap::Backup::Serializer::MboxStore.new(account.local_path, folder)
    store.uid_validity = "42" if !store.uid_validity
    serialized = to_serialized(from: from, subject: subject, body: body)
    store.add(uid, serialized)
  end

  def to_serialized(from:, subject:, body:)
    body_and_headers = <<~BODY
      From: #{from}
      Subject: #{subject}

      #{body}
    BODY
  end

  def config
    Imap::Backup::Configuration.new(
      File.expand_path("~/.imap-backup/config.json")
    )
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelpers, type: :aruba
  config.include StoreHelpers, type: :aruba
  config.include BackupDirectoryHelpers, type: :aruba

  config.before(:suite) do
    FileUtils.rm_rf "./tmp/home"
  end

  config.after do
    FileUtils.rm_rf "./tmp/home"
  end
end
