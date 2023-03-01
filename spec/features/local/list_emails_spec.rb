require "features/helper"

RSpec.describe "imap-backup local list", type: :aruba do
  let(:email) { account[:username] }
  let(:account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [account]} }
  let!(:setup) do
    create_config(**config_options)
    append_local email: email, folder: "my_folder", subject: "Ciao"
  end
  let!(:cleanup) do
    test_server.delete_folder "my_folder"
    test_server.disconnect
  end

  it "lists emails" do
    run_command_and_stop "imap-backup local list #{email} my_folder"

    expect(last_command_started).to have_output(/1: Ciao/)
  end

  context "when JSON is requested" do
    it "lists emails" do
      run_command_and_stop "imap-backup local list #{email} my_folder --format json"

      expect(last_command_started).to have_output(/"subject":"Ciao"/)
    end
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:account) { other_server_connection_parameters }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }
    let(:setup) do
      create_config(**config_options)
      append_local(
        configuration_path: custom_config_path, email: email, folder: "my_folder", subject: "Ciao"
      )
    end
    let(:cleanup) do
      other_server.delete_folder "my_folder"
      other_server.disconnect
    end

    it "lists emails" do
      run_command_and_stop(
        "imap-backup local list #{email} my_folder --config #{custom_config_path}"
      )

      expect(last_command_started).to have_output(/1: Ciao/)
    end
  end
end
