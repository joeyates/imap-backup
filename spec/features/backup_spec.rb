require "features/helper"

RSpec.describe "backup", type: :feature, docker: true do
  include_context "imap-backup connection"
  include_context "message-fixtures"

  let(:messages_as_mbox) do
    message_as_mbox_entry(msg1) + message_as_mbox_entry(msg2)
  end
  let(:folder) { "INBOX" }
  let!(:email1) { send_email folder, msg1 }
  let!(:email2) { send_email folder, msg2 }

  after do
    FileUtils.rm_rf local_backup_path
    delete_emails folder
    connection.disconnect
  end

  it "downloads messages" do
    connection.run_backup

    expect(mbox_content(folder)).to eq(messages_as_mbox)
  end

  context "IMAP metadata" do
    let(:imap_metadata) { imap_parsed(folder) }
    let(:folder_uids) { server_uids(folder) }

    it "saves IMAP metadata in a JSON file" do
      connection.run_backup

      expect { imap_metadata }.to_not raise_error
    end

    it "saves a file version" do
      connection.run_backup

      expect(imap_metadata[:version].to_s).to match(/^[0-9\.]$/)
    end

    it "records IMAP ids" do
      connection.run_backup

      expect(imap_metadata[:uids]).to eq(folder_uids)
    end

    it "records uid_validity" do
      connection.run_backup

      expect(imap_metadata[:uid_validity]).to eq(server_uid_validity(folder))
    end

    context "when an unversioned .imap file is found" do
      let!(:unversioned) do
        File.open(imap_path(folder), "w") { |f| f.write "old format imap" }
        File.open(mbox_path(folder), "w") { |f| f.write "old format emails" }
      end

      it "replaces the .imap file with a versioned JSON file" do
        connection.run_backup

        expect(imap_metadata[:uids]).to eq(folder_uids)
      end

      it "does the download" do
        connection.run_backup

        expect(mbox_content(folder)).to eq(messages_as_mbox)
      end
    end
  end
end
