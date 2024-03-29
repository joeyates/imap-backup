require "aruba/rspec"
require "json"

require "imap/backup/serializer"
require "imap/backup/serializer/mbox"

Aruba.configure do |config|
  config.home_directory = File.expand_path("./tmp/home")
  config.allow_absolute_paths = true
end

module ConfigurationHelpers
  def config_path
    File.expand_path("~/.imap-backup")
  end

  def create_config(accounts:, download_strategy: :unset, path: nil)
    path ||= File.join(config_path, "config.json")
    strategy = download_strategy == :unset ? "delay_metadata" : download_strategy
    save_data = {
      version: Imap::Backup::Configuration::VERSION,
      accounts: accounts,
      download_strategy: strategy
    }
    FileUtils.mkdir_p config_path
    FileUtils.chmod 0o700, config_path
    File.open(path, "w") { |f| f.write(JSON.pretty_generate(save_data)) }
    FileUtils.chmod(0o600, path)
  end

  def parsed_config(path: nil)
    path ||= File.join(config_path, "config.json")
    content = File.read(path)
    JSON.parse(content, symbolize_names: true)
  end
end

module DebugHelpers
  # Show Aruba output with 'clear screen' codes removed
  # to allow all output to be viewed when printed to stdout
  def command_output
    last_command_started.output.gsub("\e[H\e[2J\e[3J", "\n-- CLEAR SCREEN --\n")
  end
end

module LocalHelpers
  def create_local_folder(email:, folder:, uid_validity:, configuration_path: nil)
    account = config(configuration_path).accounts.find { |a| a.username == email }
    raise "Account not found" if !account

    FileUtils.mkdir_p account.local_path
    serializer = Imap::Backup::Serializer.new(account.local_path, folder)
    serializer.force_uid_validity uid_validity
  end

  def append_local(
    email:, folder:,
    configuration_path: nil,
    uid: 1,
    from: "sender@example.com",
    subject: "The Subject",
    body: "body",
    flags: []
  )
    account = config(configuration_path).accounts.find { |a| a.username == email }
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

  def local_path(email, configuration_path: nil)
    account = config(configuration_path).accounts.find { |a| a.username == email }
    raise "Account not found" if !account

    account.local_path
  end

  def mbox_path(email, name, configuration_path: nil, local_path: nil)
    local_path ||= local_path(email, configuration_path: configuration_path)
    File.join(local_path, "#{name}.mbox")
  end

  def mbox_content(email, name, configuration_path: nil, local_path: nil)
    path = mbox_path(
      email, name, configuration_path: configuration_path, local_path: local_path
    )
    File.read(path)
  end

  def imap_path(email, name, configuration_path: nil)
    File.join(local_path(email, configuration_path: configuration_path), "#{name}.imap")
  end

  def imap_content(email, name, configuration_path: nil)
    File.read(imap_path(email, name, configuration_path: configuration_path))
  end

  def imap_parsed(email, name, configuration_path: nil)
    content = imap_content(email, name, configuration_path: configuration_path)
    JSON.parse(content, symbolize_names: true)
  end

  def to_mbox_entry(**options)
    "From #{options[:from]}\n#{to_serialized(**options)}\n"
  end

  def config(path = nil)
    path ||= File.expand_path("~/.imap-backup/config.json")
    Imap::Backup::Configuration.new(
      path: path
    )
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelpers, type: :aruba
  config.include DebugHelpers, type: :aruba
  config.include LocalHelpers, type: :aruba

  config.before(:example, type: :aruba) do |example|
    FileUtils.rm_rf "./tmp/home" if File.directory?("./tmp/home")
    set_environment_variable("FEATURE_SPEC_ID", example.id)
  end
end
