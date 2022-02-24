require "features/helper"

RSpec.describe "restore", type: :aruba, docker: true do
  include_context "imap-backup connection"
  include_context "message-fixtures"

  let(:local_backup_path) { File.expand_path("~/backup") }
  let(:folder) { "my-stuff" }
  let(:messages_as_mbox) do
    message_as_mbox_entry(msg1) + message_as_mbox_entry(msg2)
  end
  let(:messages_as_server_messages) do
    [message_as_server_message(msg1), message_as_server_message(msg2)]
  end
  let(:message_uids) { [msg1[:uid], msg2[:uid]] }
  let(:existing_imap_content) { imap_data(uid_validity, message_uids).to_json }
  let(:uid_validity) { 1234 }

  let!(:pre) {}
  let!(:setup) do
    create_directory local_backup_path
    File.write(imap_path(folder), existing_imap_content)
    File.write(mbox_path(folder), messages_as_mbox)
    create_config(accounts: [account.to_h])

    run_command_and_stop("imap-backup restore #{account.username}")
  end
  let(:cleanup) do
    server_delete_folder folder
  end

  after { cleanup }

  context "when the folder doesn't exist" do
    it "restores messages" do
      messages = server_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq(messages_as_server_messages)
    end

    it "updates local uids to match the new server ones" do
      updated_imap_content = imap_parsed(folder)
      expect(server_uids(folder)).to eq(updated_imap_content[:uids])
    end

    it "sets the backup uid_validity to match the new folder" do
      updated_imap_content = imap_parsed(folder)
      expect(updated_imap_content[:uid_validity]).
        to eq(server_uid_validity(folder))
    end
  end

  context "when the folder exists" do
    let(:email3) { send_email folder, msg3 }

    context "when the uid_validity matches" do
      let(:pre) do
        server_create_folder folder
        email3
        uid_validity
      end
      let(:messages_as_server_messages) do
        [
          message_as_server_message(msg3),
          message_as_server_message(msg1),
          message_as_server_message(msg2)
        ]
      end
      let(:uid_validity) { server_uid_validity(folder) }

      it "appends to the existing folder" do
        messages = server_messages(folder).map { |m| server_message_to_body(m) }
        expect(messages).to eq(messages_as_server_messages)
      end
    end

    context "when the uid_validity doesn't match" do
      context "when the folder is empty" do
        let(:pre) do
          server_create_folder folder
        end

        it "sets the backup uid_validity to match the folder" do
          updated_imap_content = imap_parsed(folder)
          expect(updated_imap_content[:uid_validity]).
            to eq(server_uid_validity(folder))
        end

        it "uploads to the new folder" do
          messages = server_messages(folder).map do |m|
            server_message_to_body(m)
          end
          expect(messages).to eq(messages_as_server_messages)
        end
      end

      context "when the folder has content" do
        let(:new_folder) { "#{folder}-#{uid_validity}" }
        let(:cleanup) do
          server_delete_folder new_folder
          super()
        end

        let(:pre) do
          server_create_folder folder
          email3
        end

        it "renames the backup" do
          expect(mbox_content(new_folder)).to eq(messages_as_mbox)
        end

        it "leaves the existing folder as is" do
          messages = server_messages(folder).map do |m|
            server_message_to_body(m)
          end
          expect(messages).to eq([message_as_server_message(msg3)])
        end

        it "creates the new folder" do
          expect(server_folders.map(&:name)).to include(new_folder)
        end

        it "sets the backup uid_validity to match the new folder" do
          updated_imap_content = imap_parsed(new_folder)
          expect(updated_imap_content[:uid_validity]).
            to eq(server_uid_validity(new_folder))
        end

        it "uploads to the new folder" do
          messages = server_messages(new_folder).map do |m|
            server_message_to_body(m)
          end
          expect(messages).to eq(messages_as_server_messages)
        end
      end
    end
  end

  context "when non-Unicode encodings are used" do
    let(:server_message) do
      message_as_server_message(msg_iso8859)
    end
    let(:messages_as_mbox) do
      message_as_mbox_entry(msg_iso8859)
    end
    let(:message_uids) { [uid_iso8859] }
    let(:uid_validity) { server_uid_validity(folder) }

    let(:pre) do
      server_create_folder folder
      uid_validity
    end

    it "maintains encodings" do
      message =
        server_messages(folder).
        first["BODY[]"]

      expect(message).to eq(server_message)
    end
  end
end
