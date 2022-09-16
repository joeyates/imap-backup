require "aruba/rspec"

require "imap/backup/serializer/mbox"

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

module LocalHelpers
  def create_local_folder(email:, folder:, uid_validity:)
    account = config.accounts.find { |a| a.username == email }
    raise "Account not found" if !account

    FileUtils.mkdir_p account.local_path
    serializer = Imap::Backup::Serializer.new(account.local_path, folder)
    serializer.force_uid_validity uid_validity
  end

  def append_local(
    email:, folder:,
    uid: 1,
    from: "sender@example.com",
    subject: "The Subject",
    body: "body",
    flags: []
  )
    account = config.accounts.find { |a| a.username == email }
    raise "Account not found" if !account

    FileUtils.mkdir_p account.local_path
    serializer = Imap::Backup::Serializer.new(account.local_path, folder)
    serializer.force_uid_validity("42") if !serializer.uid_validity
    serialized = to_serialized(from: from, subject: subject, body: body)
    serializer.append uid, serialized, flags
  end

  def to_serialized(from:, subject:, body:, **_options)
    <<~BODY
      From: #{from}
      Subject: #{subject}

      #{body}
    BODY
  end

  def local_path(email)
    account = config.accounts.find { |a| a.username == email }
    raise "Account not found" if !account

    account.local_path
  end

  def mbox_path(email, name)
    File.join(local_path(email), "#{name}.mbox")
  end

  def mbox_content(email, name)
    File.read(mbox_path(email, name))
  end

  def imap_path(email, name)
    File.join(local_path(email), "#{name}.imap")
  end

  def imap_content(email, name)
    File.read(imap_path(email, name))
  end

  def imap_parsed(email, name)
    JSON.parse(imap_content(email, name), symbolize_names: true)
  end

  def to_mbox_entry(**options)
    "From #{options[:from]}\n#{to_serialized(**options)}\n"
  end

  def config
    Imap::Backup::Configuration.new(
      File.expand_path("~/.imap-backup/config.json")
    )
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelpers, type: :aruba
  config.include LocalHelpers, type: :aruba

  config.before(:suite) do
    FileUtils.rm_rf "./tmp/home"
  end

  config.before(:example, type: :aruba) do
    set_environment_variable("COVERAGE", "aruba")
  end

  config.after do
    FileUtils.rm_rf "./tmp/home"
  end
end
