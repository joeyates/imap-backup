require "features/helper"

RSpec.describe "imap-backup migrate", :docker, type: :aruba do
  let(:email) { "me@example.com" }
  let(:folder) { "migrate-folder" }
  let(:source_folder) { folder }
  let(:source_account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end
  let(:destination_account) { test_server_connection_parameters }
  let(:destination_folder) { folder }
  let(:destination_server) { test_server }
  let(:config_options) { {accounts: [source_account, destination_account]} }

  let!(:setup) do
    create_config(**config_options)
    append_local(
      email: email, folder: source_folder.gsub(".", "/"), subject: "Ciao", flags: [:Draft, :$CUSTOM]
    )
  end

  after do
    destination_server.delete_folder source_folder
    destination_server.disconnect
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) do
      {path: custom_config_path, accounts: [source_account, destination_account]}
    end

    let(:setup) do
      create_config(**config_options)
      append_local(
        configuration_path: custom_config_path,
        email: email,
        folder: source_folder,
        subject: "Ciao"
      )
    end

    it "does not raise any errors" do
      run_command_and_stop(
        "imap-backup migrate " \
        "#{email} " \
        "#{destination_account[:username]} " \
        "--config #{custom_config_path}"
      )

      expect(last_command_started).to have_exit_status(0)
    end
  end

  it "copies email to the destination account" do
    run_command_and_stop "imap-backup migrate #{email} #{destination_account[:username]}"

    messages = test_server.folder_messages(destination_folder)
    expected = <<~MESSAGE.gsub("\n", "\r\n")
      From: sender@example.com
      Subject: Ciao

      body

    MESSAGE
    expect(messages[0]["BODY[]"]).to eq(expected)
  end

  it "copies flags" do
    run_command_and_stop "imap-backup migrate #{email} #{destination_account[:username]}"

    messages = destination_server.folder_messages(destination_folder)
    expect(messages[0]["FLAGS"]).to include(:Draft)
  end

  context "when migrating from a subfolder" do
    let(:source_folder) { "my_sub.migrate-folder" }

    it "copies email from subfolders on the source account" do
      command = [
        "imap-backup",
        "migrate",
        email,
        destination_account[:username],
        "--source-prefix=my_sub",
        "--source-delimiter=."
      ].join(" ")

      run_command_and_stop command

      messages = destination_server.folder_messages(destination_folder)
      expected = <<~MESSAGE.gsub("\n", "\r\n")
        From: sender@example.com
        Subject: Ciao

        body

      MESSAGE
      expect(messages[0]["BODY[]"]).to eq(expected)
    end
  end

  context "when migrating into a subfolder" do
    let(:destination_folder) { "my_sub.migrate-folder" }

    it "copies email to subfolders on the destination account" do
      command = [
        "imap-backup",
        "migrate",
        email,
        destination_account[:username],
        "--destination-prefix=my_sub",
        "--destination-delimiter=."
      ].join(" ")

      run_command_and_stop command

      messages = destination_server.folder_messages(destination_folder)
      expected = <<~MESSAGE.gsub("\n", "\r\n")
        From: sender@example.com
        Subject: Ciao

        body

      MESSAGE
      expect(messages[0]["BODY[]"]).to eq(expected)
    end
  end

  context "when the source server has a namespace prefix" do
    let(:source_account) { other_server_connection_parameters }
    let(:source_folder) { "other_public.migrate-folder" }
    let(:email) { source_account[:username] }
    let(:destination_account) { test_server_connection_parameters }
    let(:config_options) { {accounts: [source_account, destination_account]} }

    it "copies email to the destination account" do
      command = [
        "imap-backup",
        "migrate",
        email,
        destination_account[:username],
        "--source-prefix=other_public",
        "--source-delimiter=."
      ].join(" ")

      run_command_and_stop command

      messages = destination_server.folder_messages(destination_folder)
      expected = <<~MESSAGE.gsub("\n", "\r\n")
        From: sender@example.com
        Subject: Ciao

        body

      MESSAGE
      expect(messages[0]["BODY[]"]).to eq(expected)
    end

    specify "automatic namespaces work" do
      command = [
        "imap-backup",
        "migrate",
        email,
        destination_account[:username],
        "--automatic-namespaces"
      ].join(" ")

      run_command_and_stop command

      messages = destination_server.folder_messages(destination_folder)
      expected = <<~MESSAGE.gsub("\n", "\r\n")
        From: sender@example.com
        Subject: Ciao

        body

      MESSAGE
      expect(messages[0]["BODY[]"]).to eq(expected)
    end
  end

  context "when the destination server has a namespace prefix" do
    let(:source_account) { test_server_connection_parameters }
    let(:email) { source_account[:username] }
    let(:destination_account) { other_server_connection_parameters }
    let(:destination_folder) { "other_public.migrate-folder" }
    let(:destination_server) { other_server }
    let(:config_options) { {accounts: [source_account, destination_account]} }

    it "copies email to the destination account" do
      command = [
        "imap-backup",
        "migrate",
        email,
        destination_account[:username],
        "--destination-prefix=other_public",
        "--destination-delimiter=."
      ].join(" ")

      run_command_and_stop command

      messages = destination_server.folder_messages(destination_folder)
      expected = <<~MESSAGE.gsub("\n", "\r\n")
        From: sender@example.com
        Subject: Ciao

        body

      MESSAGE
      expect(messages[0]["BODY[]"]).to eq(expected)
    end

    specify "automatic namespaces work" do
      command = [
        "imap-backup",
        "migrate",
        email,
        destination_account[:username],
        "--automatic-namespaces"
      ].join(" ")

      run_command_and_stop command

      messages = destination_server.folder_messages(destination_folder)
      expected = <<~MESSAGE.gsub("\n", "\r\n")
        From: sender@example.com
        Subject: Ciao

        body

      MESSAGE
      expect(messages[0]["BODY[]"]).to eq(expected)
    end
  end
end
