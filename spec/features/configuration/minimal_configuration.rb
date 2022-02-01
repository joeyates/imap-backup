require "features/helper"

RSpec.describe "Running commands", type: :aruba do
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

  before do
    create_config(accounts: [])
    run_command("imap-backup local accounts")
    last_command_started.stop
  end

  context "when no accounts are configured" do
    it "succeeds" do
      expect(last_command_started).to have_exit_status(0)
    end
  end
end
