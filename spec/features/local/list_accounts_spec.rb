require "features/helper"

RSpec.describe "Listing accounts", type: :aruba do
  let(:config_options) { {accounts: [{username: "me@example.com"}]} }
  let(:command) { "imap-backup local accounts" }

  before do
    create_config(**config_options)

    run_command_and_stop command
  end

  it "lists accounts" do
    expect(last_command_started).to have_output("me@example.com")
  end

  context "when JSON is requested" do
    let(:command) { "imap-backup local accounts --format json" }

    it "lists accounts" do
      expect(last_command_started).to have_output('[{"username":"me@example.com"}]')
    end
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {path: custom_config_path, accounts: [{username: "other@example.com"}]} }
    let(:command) { "imap-backup local accounts --config #{custom_config_path}" }

    it "lists accounts from the supplied config file" do
      expect(last_command_started).to have_output("other@example.com")
    end
  end
end
