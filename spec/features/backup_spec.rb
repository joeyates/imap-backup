require "features/helper"

RSpec.describe "backup", type: :aruba, docker: true do
  include_context "account fixture"
  include_context "message-fixtures"

  let(:backup_folders) { [{name: folder}] }
  let(:folder) { "my-stuff" }
  let(:messages_as_mbox) do
    to_mbox_entry(**msg1) + to_mbox_entry(**msg2)
  end
  let(:email) { test_server_connection_parameters[:username] }
  let(:write_config) { create_config(accounts: [account.to_h]) }

  let!(:pre) do
    test_server.delete_folder folder
  end
  let!(:setup) do
    test_server.create_folder folder
    test_server.send_email folder, **msg1
    test_server.send_email folder, **msg2
    write_config

    run_command_and_stop("imap-backup backup")
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "downloads messages" do
    expect(mbox_content(email, folder)).to eq(messages_as_mbox)
  end

  describe "IMAP metadata" do
    let(:imap_metadata) { imap_parsed(email, folder) }
    let(:folder_uids) { test_server.folder_uids(folder) }

    it "saves IMAP metadata in a JSON file" do
      expect { imap_metadata }.to_not raise_error
    end

    it "saves a file version" do
      expect(imap_metadata[:version].to_s).to match(/^[0-9.]$/)
    end

    it "records IMAP ids" do
      uids = imap_metadata[:messages].map { |m| m[:uid] }

      expect(uids).to eq(folder_uids)
    end

    it "records message offsets in the mbox file" do
      offsets = imap_metadata[:messages].map { |m| m[:offset] }
      expected = [0, to_mbox_entry(**msg1).length]

      expect(offsets).to eq(expected)
    end

    it "records message lengths in the mbox file" do
      lengths = imap_metadata[:messages].map { |m| m[:length] }
      expected = [to_mbox_entry(**msg1).length, to_mbox_entry(**msg2).length]

      expect(lengths).to eq(expected)
    end

    it "records uid_validity" do
      expect(imap_metadata[:uid_validity]).to eq(test_server.folder_uid_validity(folder))
    end

    context "when uid_validity does not match" do
      let(:new_name) { "NEWNAME" }
      let(:original_folder_uid_validity) { test_server.folder_uid_validity(folder) }
      let(:connection) { Imap::Backup::Account::Connection.new(account) }
      let!(:pre) do
        super()
        test_server.delete_folder new_name
        test_server.create_folder folder
        test_server.send_email folder, **msg3
        original_folder_uid_validity
        connection.run_backup
        connection.disconnect
        test_server.rename_folder folder, new_name
      end
      let(:renamed_folder) { "#{folder}-#{original_folder_uid_validity}" }

      after do
        test_server.delete_folder new_name
      end

      it "renames the old backup" do
        expect(mbox_content(email, renamed_folder)).to eq(to_mbox_entry(**msg3))
      end

      it "renames the old metadata file" do
        expect(imap_parsed(email, renamed_folder)).to be_a Hash
      end

      it "downloads messages" do
        expect(mbox_content(email, folder)).to eq(messages_as_mbox)
      end

      it "creates a metadata file" do
        expect(imap_parsed(email, folder)).to be_a Hash
      end

      context "when a renamed local backup exists" do
        let!(:pre) do
          super()
          create_directory local_backup_path
          valid_imap_data = {version: 3, uid_validity: 1, messages: []}
          imap_path = File.join(local_backup_path, "#{renamed_folder}.imap")
          File.write(imap_path, valid_imap_data.to_json)
          mbox_path = File.join(local_backup_path, "#{renamed_folder}.mbox")
          File.write(mbox_path, "existing mbox")
        end

        it "renames the renamed backup to a uniquely name" do
          renamed = "#{folder}-#{original_folder_uid_validity}-1"
          expect(mbox_content(email, renamed)).to eq(to_mbox_entry(**msg3))
        end
      end
    end
  end
end
