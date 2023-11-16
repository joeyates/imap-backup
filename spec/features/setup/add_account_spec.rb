require "features/helper"

RSpec.describe "imap-backup setup - adding an account", type: :aruba do
  let(:account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [account]} }

  before do
    create_config(**config_options)

    run_command "imap-backup setup"
    last_command_started.write "add account\n"
    last_command_started.write "new@example.com\n"
    last_command_started.write "(q) return to main menu\n"
    last_command_started.write "save and exit\n"
    last_command_started.stop
  end

  it "creates the configuration directory" do
    expect(directory?(config_path)).to be true
  end

  it "saves account info" do
    config = parsed_config
    account = config[:accounts].last

    expect(account[:username]).to eq("new@example.com")
  end
end
