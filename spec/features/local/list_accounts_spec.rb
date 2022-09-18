require "features/helper"

RSpec.describe "Listing accounts", type: :aruba do
  let(:config_options) { {accounts: [{username: "me@example.com"}]} }
  let(:command) { "imap-backup local accounts" }

  before do
    create_config **config_options
    run_command_and_stop command
  end

  it "lists accounts" do
    expect(last_command_started).to have_output("me@example.com")
  end
end
