require "features/helper"

RSpec.describe "Mirroring", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:folder) { "my_folder" }
  let(:source_account) do
    {
      username: "address@example.com",
      password: "pass",
      mirror_mode: true,
      folders: [{name: folder}],
      local_path: File.join(config_path, "address_example.com"),
      server: "localhost",
      connection_options: {
        port: 8993,
        ssl: {verify_mode: 0}
      }
    }
  end
  let(:destination_account) do
    {
      username: "email@other.org",
      password: "pass",
      local_path: File.join(config_path, "email_other.org"),
      server: "localhost",
      connection_options: {
        port: 9993,
        ssl: {verify_mode: 0}
      }
    }
  end
  let(:mirror_file_path) { File.join(source_account[:local_path], "#{folder}.mirror") }
  let(:msg1_source_uid) { test_server.folder_uids(folder).first }
  let(:msg1_destination_id) { other_server.folder_uids(folder).first }
  let(:pre) { nil }

  before do
    test_server.create_folder folder
    test_server.send_email folder, **msg1, flags: [:Seen]

    create_config accounts: [source_account, destination_account]

    pre

    run_command_and_stop "imap-backup mirror #{source_account[:username]} #{destination_account[:username]}"
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
    other_server.delete_folder folder
    other_server.disconnect
  end

  it "backs up the source account" do
    content = mbox_content(source_account[:username], folder)

    expect(content).to eq(to_mbox_entry(**msg1))
  end

  it "creates the destination folder" do
    expect(other_server.folder_exists?(folder)).to be true
  end

  it "appends all emails" do
    messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
    expect(messages).to eq([message_as_server_message(**msg1)])
  end

  it "sets flags" do
    flags = other_server.folder_messages(folder).first["FLAGS"]
    flags.reject! { |f| f == :Recent }
    expect(flags).to eq([:Seen])
  end

  it "saves the .mirror file" do
    content = JSON.parse(File.read(mirror_file_path))
    map = content.dig(destination_account[:username], "map")

    expect(map).to eq({msg1_source_uid.to_s => msg1_destination_id})
  end

  context "when there are emails on the destination server" do
    let(:pre) do
      other_server.create_folder folder
      other_server.send_email folder, **msg2
    end

    it "deletes them" do
      messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq([message_as_server_message(**msg1)])
    end
  end

  context "when a mirror file exists" do
    let(:mirror_contents) do
      {
        destination_account[:username] => {
          "source_uid_validity" => test_server.folder_uid_validity(folder),
          "destination_uid_validity" => other_server.folder_uid_validity(folder),
          "map" => {
            msg1_source_uid => msg1_destination_id
          }
        }
      }
    end
    let!(:mirror_file) do
      FileUtils.mkdir_p source_account[:local_path]
      File.write(mirror_file_path, mirror_contents.to_json)
    end
    let(:pre) do
      # msg1 on both, msg2 on source
      other_server.create_folder folder
      other_server.send_email folder, **msg1
      test_server.send_email folder, **msg2
    end

    it "appends missing emails" do
      messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq([message_as_server_message(**msg1), message_as_server_message(**msg2)])
    end

    context "when there are emails on the destination server that are not on the source server" do
      let(:pre) do
        super()
        other_server.send_email folder, **msg3
      end

      it "deletes them" do
        messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
        expect(messages).to eq([message_as_server_message(**msg1), message_as_server_message(**msg2)])
      end
    end
  end
end
