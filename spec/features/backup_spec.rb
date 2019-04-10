require "features/helper"

RSpec.describe "backup", type: :feature, docker: true do
  include_context "imap-backup connection"
  include_context "message-fixtures"

  let(:messages_as_mbox) do
    message_as_mbox_entry(msg1) + message_as_mbox_entry(msg2)
  end
  let(:folder) { "my-stuff" }
  let(:email1) { send_email folder, msg1 }
  let(:email2) { send_email folder, msg2 }
  let!(:pre) {}
  let!(:setup) do
    server_create_folder folder
    email1
    email2
    connection.run_backup
  end

  after do
    FileUtils.rm_rf local_backup_path
    delete_emails folder
    server_delete_folder folder
    connection.disconnect
  end

  it "downloads messages" do
    expect(mbox_content(folder)).to eq(messages_as_mbox)
  end

  describe "IMAP metadata" do
    let(:imap_metadata) { imap_parsed(folder) }
    let(:folder_uids) { server_uids(folder) }

    it "saves IMAP metadata in a JSON file" do
      expect { imap_metadata }.to_not raise_error
    end

    it "saves a file version" do
      expect(imap_metadata[:version].to_s).to match(/^[0-9\.]$/)
    end

    it "records IMAP ids" do
      expect(imap_metadata[:uids]).to eq(folder_uids)
    end

    it "records uid_validity" do
      expect(imap_metadata[:uid_validity]).to eq(server_uid_validity(folder))
    end

    context "when uid_validity does not match" do
      let(:new_name) { "NEWNAME" }
      let(:email3) { send_email folder, msg3 }
      let(:original_folder_uid_validity) { server_uid_validity(folder) }
      let!(:pre) do
        server_create_folder folder
        email3
        original_folder_uid_validity
        connection.run_backup
        server_rename_folder folder, new_name
      end
      let(:renamed_folder) { folder + "." + original_folder_uid_validity.to_s }

      after do
        server_delete_folder new_name
      end

      it "renames the old backup" do
        expect(mbox_content(renamed_folder)).to eq(message_as_mbox_entry(msg3))
      end

      it "downloads messages" do
        expect(mbox_content(folder)).to eq(messages_as_mbox)
      end

      context "when a renamed local backup exists" do
        let!(:pre) do
          super()
          File.write(imap_path(renamed_folder), "existing imap")
          File.write(mbox_path(renamed_folder), "existing mbox")
        end

        it "moves the old backup to a uniquely named directory" do
          renamed = folder + "." + original_folder_uid_validity.to_s + ".1"
          expect(mbox_content(renamed)).to eq(message_as_mbox_entry(msg3))
        end
      end
    end

    context "when an unversioned .imap file is found" do
      let!(:pre) do
        File.open(imap_path(folder), "w") { |f| f.write "old format imap" }
        File.open(mbox_path(folder), "w") { |f| f.write "old format emails" }
      end

      it "replaces the .imap file with a versioned JSON file" do
        expect(imap_metadata[:uids]).to eq(folder_uids)
      end

      it "does the download" do
        expect(mbox_content(folder)).to eq(messages_as_mbox)
      end
    end
  end
end
