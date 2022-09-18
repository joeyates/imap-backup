require "features/helper"

RSpec.describe "Listing accounts", type: :aruba do
  let(:config_options) { {accounts: [{username: "me@example.com"}]} }

  before do
    create_config **config_options
    run_command_and_stop("imap-backup local accounts")
  end

  it "lists accounts" do
    expect(last_command_started).to have_output("me@example.com")
  end
end
