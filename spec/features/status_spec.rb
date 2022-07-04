require "features/helper"
require "imap/backup/cli/status"

RSpec.describe "status", type: :aruba, docker: true do
  include_context "account fixture"
  include_context "message-fixtures"

  let(:folder) { "my-stuff" }

  before do
    create_config(accounts: [account.to_h])
    server_create_folder folder
    send_email folder, msg1
    disconnect_imap

    run_command_and_stop("imap-backup status")
  end

  after do
    server_delete_folder folder
    disconnect_imap
  end

  it "prints the count of messages to download" do
    expect(last_command_started).to have_output(/^my-stuff: 1$/)
  end
end
