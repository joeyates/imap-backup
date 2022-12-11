require "features/helper"

RSpec.describe "Mirroring", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:folder) { "my_folder" }
  let(:mirror_file_path) do
    File.join(test_server_connection_parameters[:local_path], "#{folder}.mirror")
  end
  let(:msg1_source_uid) { test_server.folder_uids(folder).first }
  let(:msg1_destination_id) { other_server.folder_uids(folder).first }
  let(:config_options) do
    {
      accounts: [
        test_server_connection_parameters, other_server_connection_parameters
      ]
    }
  end
  let(:command) do
    "imap-backup mirror " \
      "#{test_server_connection_parameters[:username]} " \
      "#{other_server_connection_parameters[:username]}"
  end

  before do
    test_server.create_folder folder
    test_server.send_email folder, **msg1, flags: [:Seen]
    create_config(**config_options)
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
    other_server.delete_folder folder
    other_server.disconnect
  end

  it "backs up the source account" do
    run_command_and_stop command

    content = mbox_content(test_server_connection_parameters[:username], folder)

    expect(content).to eq(to_mbox_entry(**msg1))
  end

  it "creates the destination folder" do
    run_command_and_stop command

    expect(other_server.folder_exists?(folder)).to be true
  end

  it "appends all emails" do
    run_command_and_stop command

    messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
    expect(messages).to eq([message_as_server_message(**msg1)])
  end

  it "sets flags" do
    run_command_and_stop command

    flags = other_server.folder_messages(folder).first["FLAGS"]
    flags.reject! { |f| f == :Recent }
    expect(flags).to eq([:Seen])
  end

  it "saves the .mirror file" do
    run_command_and_stop command

    content = JSON.parse(File.read(mirror_file_path))
    map = content.dig(other_server_connection_parameters[:username], "map")

    expect(map).to eq({msg1_source_uid.to_s => msg1_destination_id})
  end

  context "when there are emails on the destination server" do
    before do
      other_server.create_folder folder
      other_server.send_email folder, **msg2
    end

    it "deletes them" do
      run_command_and_stop command

      messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq([message_as_server_message(**msg1)])
    end
  end

  context "when a mirror file exists" do
    let(:mirror_contents) do
      {
        other_server_connection_parameters[:username] => {
          "source_uid_validity" => test_server.folder_uid_validity(folder),
          "destination_uid_validity" => other_server.folder_uid_validity(folder),
          "map" => {
            msg1_source_uid => msg1_destination_id
          }
        }
      }
    end
    let(:mirror_file) do
      FileUtils.mkdir_p test_server_connection_parameters[:local_path]
      File.write(mirror_file_path, mirror_contents.to_json)
    end

    before do
      # msg1 on both, msg2 on source
      other_server.create_folder folder
      other_server.send_email folder, **msg1
      test_server.send_email folder, **msg2
      mirror_file
    end

    it "appends missing emails" do
      run_command_and_stop command

      messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq([message_as_server_message(**msg1), message_as_server_message(**msg2)])
    end

    context "when flags have changed" do
      before do
        other_server.create_folder folder
        other_server.send_email folder, **msg1, flags: [:Draft]
        mirror_file
      end

      it "updates them" do
        run_command_and_stop command

        flags = other_server.folder_messages(folder).first["FLAGS"]
        flags.reject! { |f| f == :Recent }
        expect(flags).to eq([:Seen])
      end
    end

    context "when there are emails on the destination server that are not on the source server" do
      before do
        other_server.send_email folder, **msg3
      end

      it "deletes them" do
        run_command_and_stop command

        messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
        expect(messages).to eq(
          [
            message_as_server_message(**msg1),
            message_as_server_message(**msg2)
          ]
        )
      end
    end
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) do
      {
        path: custom_config_path,
        accounts: [
          test_server_connection_parameters, other_server_connection_parameters
        ]
      }
    end
    let(:command) do
      "imap-backup mirror " \
        "#{test_server_connection_parameters[:username]} " \
        "#{other_server_connection_parameters[:username]} " \
        "--config #{custom_config_path}"
    end

    it "copies messages" do
      run_command_and_stop command

      messages = other_server.folder_messages(folder).map { |m| server_message_to_body(m) }
      expect(messages).to eq([message_as_server_message(**msg1)])
    end
  end
end
