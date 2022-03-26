require "features/helper"
require "imap/backup/cli/folders"

RSpec.describe "folders", type: :aruba, docker: true do
  let(:account) { fixture("connection") }
  let(:options) { {accounts: account[:username]} }

  before do
    create_config(accounts: [account])

    run_command_and_stop("imap-backup folders")
  end

  it "lists account folders" do
    expect(last_command_started).to have_output(/^\tINBOX$/)
  end
end
