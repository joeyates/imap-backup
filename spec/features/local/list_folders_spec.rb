require "features/helper"

RSpec.describe "imap-backup local folders", type: :aruba do
  let(:account) { test_server_connection_parameters }
  let(:configuration_path) { File.join(config_path, "config.json") }
  let(:config_options) { {accounts: [account]} }
  let(:command) { "imap-backup local folders #{account[:username]}" }

  before do
    create_config(**config_options)
    append_local(
      configuration_path: configuration_path,
      email: account[:username],
      folder: "my_folder",
      body: "Hi"
    )

    run_command_and_stop command
  end

  it "lists folders that have been backed up" do
    expect(last_command_started).to have_output('"my_folder"')
  end

  context "when JSON is requested" do
    let(:command) { "imap-backup local folders #{account[:username]} --format json" }

    it "lists folders as JSON" do
      expect(last_command_started).to have_output(/\{"name":"my_folder"\}/)
    end
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:configuration_path) { custom_config_path }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }
    let(:command) do
      "imap-backup local folders #{account[:username]} --config #{custom_config_path}"
    end

    it "lists folders" do
      expect(last_command_started).to have_output('"my_folder"')
    end
  end
end
