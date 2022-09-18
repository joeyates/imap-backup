require "features/helper"
require "imap/backup/cli/status"

RSpec.describe "status", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:folder) { "my-stuff" }
  let(:config_options) { {accounts: [test_server_connection_parameters]} }
  let(:command) { "imap-backup status" }

  before do
    test_server.create_folder folder
    test_server.send_email folder, **msg1
    test_server.disconnect
    create_config **config_options

    run_command_and_stop command
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "prints the count of messages to download" do
    expect(last_command_started).to have_output(/^my-stuff: 1$/)
  end
end
