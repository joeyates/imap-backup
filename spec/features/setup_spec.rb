require "features/helper"

RSpec.describe "imap-backup setup", type: :aruba do
  let(:config_options) { {accounts: []} }
  let(:command) { "imap-backup setup" }
  let!(:setup) do
    create_config(**config_options)
  end

  it "shows the main menu" do
    run_command command
    last_command_started.write "q\n"
    last_command_started.stop

    expect(last_command_started).to have_output(/imap-backup - Main Menu/)
  end

  context "when the configuration file does not exist" do
    let(:setup) {}

    it "does not raise any errors" do
      run_command command
      last_command_started.write "q\n"
      last_command_started.stop

      expect(last_command_started).to have_exit_status(0)
    end
  end

  context "when a config path is supplied" do
    let(:account) { other_server_connection_parameters }
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }
    let(:command) { "imap-backup setup --config #{custom_config_path}" }

    it "shows that configuration's accounts" do
      run_command command
      last_command_started.write "q\n"
      last_command_started.stop

      expect(last_command_started).to have_output(/1. #{account[:username]}/)
    end
  end
end
