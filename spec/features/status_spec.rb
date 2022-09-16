require "features/helper"
require "imap/backup/cli/status"

RSpec.describe "status", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:account) { test_server_connection_parameters }
  let(:folder) { "my-stuff" }

  before do
    create_config(accounts: [account.to_h])
    test_server.create_folder folder
    test_server.send_email folder, **msg1
    test_server.disconnect

    run_command_and_stop("imap-backup status")
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "prints the count of messages to download" do
    expect(last_command_started).to have_output(/^my-stuff: 1$/)
  end
end
