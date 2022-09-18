require "features/helper"

RSpec.describe "stats", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:account) { test_server_connection_parameters }
  let(:folder) { "my-stuff" }
  let(:command) { "stats #{account[:username]}" }
  let(:config_options) { {accounts: [account]} }

  before do
    test_server.create_folder folder
    test_server.send_email folder, **msg1
    test_server.disconnect
    create_config **config_options

    run_command_and_stop "imap-backup #{command}"
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "lists messages to be backed up" do
    expect(last_command_started).to have_output(/my-stuff\s+\|\s+1\|\s+0\|\s+0/)
  end

  context "when JSON is requested" do
    let(:command) { "stats #{account[:username]} --format json" }

    it "produces JSON" do
      expect(last_command_started).
        to have_output(/\{"folder":"my-stuff","remote":1,"both":0,"local":0\}/)
    end
  end
end
