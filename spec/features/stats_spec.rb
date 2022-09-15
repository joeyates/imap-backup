require "features/helper"

RSpec.describe "stats", type: :aruba, docker: true do
  include_context "account fixture"
  include_context "message-fixtures"

  let(:folder) { "my-stuff" }
  let(:command) { "stats #{account.username}" }

  before do
    test_server.create_folder folder
    test_server.send_email folder, **msg1
    create_config accounts: [account.to_h]
    test_server.disconnect

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
    let(:command) { "stats #{account.username} --format json" }

    it "produces JSON" do
      expect(last_command_started).
        to have_output(/\{"folder":"my-stuff","remote":1,"both":0,"local":0\}/)
    end
  end
end
