require "features/helper"

RSpec.describe "ignore history", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:account) { test_server_connection_parameters }
  let(:email) { account[:username] }
  let(:folder) { "my_folder" }
  let(:config_options) { {accounts: [account]} }
  let(:expected_mbox_content) do
    <<~MESSAGE
      From fake@email.com
      From: fake@email.com
      Subject: Message 1 not backed up
      Skipped 1

    MESSAGE
  end

  let!(:setup) do
    test_server.create_folder folder
    test_server.send_email folder, **msg1
    create_config(**config_options)
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "fills the .imap file with dummy data" do
    run_command_and_stop "imap-backup utils ignore-history #{email}"

    content = imap_parsed(email, folder)

    expect(content[:messages].count).to eq(1)
  end

  it "fills the .mbox file with dummy data" do
    run_command_and_stop "imap-backup utils ignore-history #{email}"

    content = mbox_content(email, folder)

    expect(content).to eq(expected_mbox_content)
  end

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }

    it "works" do
      run_command_and_stop(
        "imap-backup utils ignore-history #{email} --config #{custom_config_path}"
      )

      content = imap_parsed(email, folder, configuration_path: custom_config_path)

      expect(content[:messages].count).to eq(1)
    end
  end
end
