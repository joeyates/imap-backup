require "features/helper"

RSpec.describe "List account folders", type: :aruba do
  let(:account) do
    fixture("connection")
  end

  before do
    create_config(accounts: [account])
    run_command_and_stop("imap-backup remote folders #{account[:username]}")
  end

  it "lists folders" do
    expect(last_command_started).to have_output(/"INBOX"/)
  end
end
