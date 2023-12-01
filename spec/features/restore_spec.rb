require "features/helper"

RSpec.describe "imap-backup restore", :container, type: :aruba do
  include_context "message-fixtures"

  let(:account_config) { test_server_connection_parameters.merge(folders: [folder]) }
  let(:folder) { "stuff-to-restore" }
  let(:messages_as_mbox) do
    to_mbox_entry(**message_one) + to_mbox_entry(**message_two)
  end
  let(:messages_as_server_messages) do
    [message_as_server_message(**message_one), message_as_server_message(**message_two)]
  end
  let(:uid_validity) { 1234 }
  let(:config_options) { {accounts: [account_config]} }
  let(:email) { account_config[:username] }

  let!(:pre) { test_server.warn_about_non_default_folders }
  let!(:setup) do
    create_config(**config_options)
    create_local_folder email: email, folder: folder, uid_validity: uid_validity
    append_local email: email, folder: folder, flags: [:Flagged], **message_one
    append_local(
      email: email, folder: folder, flags: [:Draft, :$NON_SYSTEM_FLAG], **message_two
    )
  end
  let(:run_command) { run_command_and_stop("imap-backup restore #{email}") }
  let(:cleanup) do
    test_server.delete_folder folder
    test_server.disconnect
  end

  after { cleanup }

  context "when the folder doesn't exist" do
    it "restores messages" do
      run_command

      messages = test_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq(messages_as_server_messages)
    end

    it "restores flags" do
      run_command

      messages = test_server.folder_messages(folder)
      flags = messages.map { |m| m["FLAGS"] }

      expect(flags[0]).to include(:Flagged)
    end

    it "updates local uids to match the new server ones" do
      run_command

      updated_imap_content = imap_parsed(email, folder)
      stored_uids = updated_imap_content[:messages].map { |m| m[:uid] }
      expect(test_server.folder_uids(folder)).to eq(stored_uids)
    end

    it "sets the backup uid_validity to match the new folder" do
      run_command

      updated_imap_content = imap_parsed(email, folder)
      expect(updated_imap_content[:uid_validity]).
        to eq(test_server.folder_uid_validity(folder))
    end
  end

  context "when the folder exists" do
    let(:email3) { test_server.send_email folder, **message_three }

    context "when the uid_validity matches" do
      let(:setup) do
        test_server.create_folder folder
        email3
        uid_validity
        super()
      end
      let(:messages_as_server_messages) do
        [
          message_as_server_message(**message_three),
          message_as_server_message(**message_one),
          message_as_server_message(**message_two)
        ]
      end
      let(:uid_validity) { test_server.folder_uid_validity(folder) }

      it "appends to the existing folder" do
        run_command

        messages = test_server.folder_messages(folder).map { |m| server_message_to_body(m) }
        expect(messages).to eq(messages_as_server_messages)
      end
    end

    context "when the uid_validity doesn't match" do
      context "when the folder is empty" do
        let(:setup) do
          test_server.create_folder folder
          super()
        end

        it "sets the backup uid_validity to match the folder" do
          run_command

          updated_imap_content = imap_parsed(email, folder)
          expect(updated_imap_content[:uid_validity]).
            to eq(test_server.folder_uid_validity(folder))
        end

        it "uploads to the new folder" do
          run_command

          messages = test_server.folder_messages(folder).map do |m|
            server_message_to_body(m)
          end
          expect(messages).to eq(messages_as_server_messages)
        end
      end

      context "when the folder has content" do
        let(:new_folder) { "#{folder}-#{uid_validity}" }
        let(:setup) do
          test_server.create_folder folder
          email3
          super()
        end
        let(:cleanup) do
          test_server.delete_folder new_folder
          super()
        end

        it "renames the backup" do
          run_command

          expect(mbox_content(email, new_folder)).to eq(messages_as_mbox)
        end

        it "leaves the existing folder as is" do
          run_command

          messages = test_server.folder_messages(folder).map do |m|
            server_message_to_body(m)
          end
          expect(messages).to eq([message_as_server_message(**message_three)])
        end

        it "creates the new folder" do
          run_command

          expect(test_server.folders.map(&:name)).to include(new_folder)
        end

        it "sets the backup uid_validity to match the new folder" do
          run_command

          updated_imap_content = imap_parsed(email, new_folder)
          expect(updated_imap_content[:uid_validity]).
            to eq(test_server.folder_uid_validity(new_folder))
        end

        it "uploads to the new folder" do
          run_command

          messages = test_server.folder_messages(new_folder).map do |m|
            server_message_to_body(m)
          end
          expect(messages).to eq(messages_as_server_messages)
        end
      end
    end
  end

  context "when non-Unicode encodings are used" do
    let(:uid_validity) { test_server.folder_uid_validity(folder) }

    let(:setup) do
      test_server.create_folder folder
      uid_validity
      create_config accounts: [account_config]
      create_local_folder email: email, folder: folder, uid_validity: uid_validity
      append_local email: email, folder: folder, **msg_iso8859
    end

    it "maintains encodings" do
      run_command

      message =
        test_server.folder_messages(folder).
        first["BODY[]"]

      server_message = message_as_server_message(**msg_iso8859)

      expect(message).to eq(server_message)
    end
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { super().merge(path: custom_config_path) }

    let(:setup) do
      create_config(**config_options)
      create_local_folder(
        configuration_path: custom_config_path,
        email: email,
        folder: folder,
        uid_validity: uid_validity
      )
      append_local(
        configuration_path: custom_config_path,
        email: email,
        folder: folder,
        flags: [:Flagged],
        **message_one
      )
    end
    let(:run_command) do
      run_command_and_stop(
        "imap-backup restore #{email} --config #{custom_config_path}"
      )
    end

    it "does not raise any errors" do
      run_command

      expect(last_command_started).to have_exit_status(0)
    end

    it "restores messages" do
      run_command

      messages = test_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq([message_as_server_message(**message_one)])
    end
  end
end
