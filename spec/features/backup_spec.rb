require "features/helper"

RSpec.describe "backup", type: :aruba, docker: true do
  include_context "imap-backup connection"
  include_context "message-fixtures"

  let(:local_backup_path) { File.expand_path("~/backup") }
  let(:backup_folders) { [{name: folder}] }
  let(:folder) { "my-stuff" }
  let(:messages_as_mbox) do
    message_as_mbox_entry(msg1) + message_as_mbox_entry(msg2)
  end

  let!(:pre) {}
  let!(:setup) do
    server_create_folder folder
    send_email folder, msg1
    send_email folder, msg2
    create_config(accounts: [account.to_h])

    run_command_and_stop("imap-backup backup")
  end

  after do
    server_delete_folder folder
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
      expect(imap_metadata[:version].to_s).to match(/^[0-9.]$/)
    end

    it "records IMAP ids" do
      expect(imap_metadata[:uids]).to eq(folder_uids)
    end

    it "records uid_validity" do
      expect(imap_metadata[:uid_validity]).to eq(server_uid_validity(folder))
    end

    context "when uid_validity does not match" do
      let(:new_name) { "NEWNAME" }
      let(:original_folder_uid_validity) { server_uid_validity(folder) }
      let!(:pre) do
        server_create_folder folder
        send_email folder, msg3
        original_folder_uid_validity
        connection.run_backup
        connection.disconnect
        server_rename_folder folder, new_name
      end
      let(:renamed_folder) { "#{folder}-#{original_folder_uid_validity}" }

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
          create_directory local_backup_path
          File.write(imap_path(renamed_folder), "existing imap")
          File.write(mbox_path(renamed_folder), "existing mbox")
        end

        it "moves the old backup to a uniquely named directory" do
          renamed = "#{folder}-#{original_folder_uid_validity}-1"
          expect(mbox_content(renamed)).to eq(message_as_mbox_entry(msg3))
        end
      end
    end

    context "when an unversioned .imap file is found" do
      let!(:pre) do
        create_directory local_backup_path
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
