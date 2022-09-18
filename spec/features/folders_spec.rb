require "features/helper"
require "imap/backup/cli/folders"

RSpec.describe "folders", type: :aruba, docker: true do
  let(:account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [account]} }

  before do
    create_config **config_options

    run_command_and_stop("imap-backup folders")
  end

  it "lists account folders" do
    expect(last_command_started).to have_output(/^\tINBOX$/)
  end
end
