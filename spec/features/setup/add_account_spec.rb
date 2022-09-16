require "features/helper"

RSpec.describe "adding an account", type: :aruba do
  let(:home_directory) { File.expand_path("./tmp/home") }
  let(:imap_directory) { File.join(home_directory, ".imap-backup") }
  let(:config_path) { File.join(imap_directory, "config.json") }

  before do
    run_command "imap-backup setup"
    last_command_started.write "add account\n"
    last_command_started.write "me@example.com\n"
    last_command_started.write "(q) return to main menu\n"
    last_command_started.write "save and exit\n"
    last_command_started.stop
  end

  it "works" do
    expect(last_command_started).to have_exit_status(0)
  end

  it "creates the configuration directory" do
    expect(directory?(imap_directory)).to be true
  end

  it "saves account info" do
    content = read(config_path).join("\n")
    config = JSON.parse(content)
    account = config["accounts"].first

    expect(account["username"]).to eq("me@example.com")
  end
end
