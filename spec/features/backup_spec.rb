require "features/helper"

RSpec.describe "backup", type: :feature, docker: true do
  include_context "imap-backup connection"
  include_context "message-fixtures"

  let(:messages_as_mbox) do
    message_as_mbox_entry(msg1) + message_as_mbox_entry(msg2)
  end
  let(:folder) { "INBOX" }

  before do
    send_email folder, msg1
    send_email folder, msg2
  end

  after do
    FileUtils.rm_rf local_backup_path
    delete_emails folder
  end

  it "downloads messages" do
    connection.run_backup

    expect(mbox_content(folder)).to eq(messages_as_mbox)
  end
end
