require "features/helper"

RSpec.describe "restore", type: :aruba, docker: true do
  include_context "account fixture"
  include_context "message-fixtures"

  let(:folder) { "my-stuff" }
  let(:messages_as_mbox) do
    message_as_mbox_entry(msg1) + message_as_mbox_entry(msg2)
  end
  let(:messages_as_server_messages) do
    [message_as_server_message(msg1), message_as_server_message(msg2)]
  end
  let(:uid_validity) { 1234 }

  let!(:pre) {}
  let!(:setup) do
    create_config accounts: [account.to_h]
    create_files email: account.username, folder: folder, uid_validity: uid_validity
    store_email email: account.username, folder: folder, flags: [:Flagged], **msg1
    store_email email: account.username, folder: folder, flags: [:Draft], **msg2

    run_command_and_stop("imap-backup restore #{account.username}")
  end
  let(:cleanup) do
    server_delete_folder folder
    disconnect_imap
  end

  after { cleanup }

  context "when the folder doesn't exist" do
    it "restores messages" do
      messages = server_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq(messages_as_server_messages)
    end

    it "restores flags" do
      messages = server_messages(folder)
      flags = messages.map { |m| m["FLAGS"] }

      expect(flags[0]).to include(:Flagged)
    end

    it "updates local uids to match the new server ones" do
      updated_imap_content = imap_parsed(folder)
      stored_uids = updated_imap_content[:messages].map { |m| m[:uid] }
      expect(server_uids(folder)).to eq(stored_uids)
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
        let(:pre) do
          server_create_folder folder
          email3
        end
        let(:cleanup) do
          server_delete_folder new_folder
          super()
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
    let(:uid_validity) { server_uid_validity(folder) }

    let(:setup) do
      server_create_folder folder
      uid_validity
      create_config accounts: [account.to_h]
      create_files email: account.username, folder: folder, uid_validity: uid_validity
      store_email email: account.username, folder: folder, **msg_iso8859

      run_command_and_stop("imap-backup restore #{account.username}")
    end

    it "maintains encodings" do
      message =
        server_messages(folder).
        first["BODY[]"]

      server_message = message_as_server_message(msg_iso8859)

      expect(message).to eq(server_message)
    end
  end
end
