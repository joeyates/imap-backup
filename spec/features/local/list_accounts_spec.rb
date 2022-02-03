require "features/helper"

RSpec.describe "Listing accounts", type: :aruba do
  before do
    create_config(accounts: [{"username": "me@example.com"}])
    run_command_and_stop("imap-backup local accounts")
  end

  it "lists accounts" do
    expect(last_command_started).to have_output("me@example.com")
  end
end
