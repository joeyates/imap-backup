require "aruba/rspec"

Aruba.configure do |config|
  config.home_directory = File.expand_path("./tmp/home")
end

module ConfigurationHelpers
  def create_config(accounts:, debug: false)
    config_path = File.expand_path("~/.imap-backup")
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

RSpec.configure do |config|
  config.include ConfigurationHelpers, type: :aruba

  config.before(:suite) do
    FileUtils.rm_rf "./tmp/home"
  end

  config.after do
    FileUtils.rm_rf "./tmp/home"
  end
end
