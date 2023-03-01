require "features/helper"

RSpec.describe "imap-backup migrate", type: :aruba, docker: true do
  let(:email) { "me@example.com" }
  let(:folder) { "my_folder" }
  let(:source_account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end
  let(:destination_account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [source_account, destination_account]} }

  let!(:setup) do
    create_config(**config_options)
    append_local(email: email, folder: folder, subject: "Ciao", flags: [:Draft, :$CUSTOM])
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
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
        folder: folder,
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

    messages = test_server.folder_messages(folder)
    expected = <<~MESSAGE.gsub("\n", "\r\n")
      From: sender@example.com
      Subject: Ciao

      body

    MESSAGE
    expect(messages[0]["BODY[]"]).to eq(expected)
  end

  it "copies flags" do
    run_command_and_stop "imap-backup migrate #{email} #{destination_account[:username]}"

    messages = test_server.folder_messages(folder)
    expect(messages[0]["FLAGS"]).to include(:Draft)
  end
end
