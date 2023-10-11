require "features/helper"

RSpec.describe "imap-backup stats", :docker, type: :aruba do
  include_context "message-fixtures"

  let(:account) { test_server_connection_parameters }
  let(:folder) { "stats-stuff" }
  let(:command) { "imap-backup stats #{account[:username]}" }
  let(:config_options) { {accounts: [account]} }
  let!(:setup) do
    test_server.warn_about_non_default_folders
    test_server.create_folder folder
    test_server.send_email folder, **message_one
    test_server.disconnect
    create_config(**config_options)
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "lists messages to be backed up" do
    run_command_and_stop command

    expect(last_command_started).to have_output(/stats-stuff\s+\|\s+1\|\s+0\|\s+0/)
  end

  context "when JSON is requested" do
    let(:command) { "imap-backup stats #{account[:username]} --format json" }

    it "produces JSON" do
      run_command_and_stop command

      expect(last_command_started).
        to have_output(/\{"folder":"stats-stuff","remote":1,"both":0,"local":0\}/)
    end
  end

  context "when a config path is supplied" do
    let(:account) { other_server_connection_parameters }
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }
    let(:command) do
      "imap-backup stats #{account[:username]} --config #{custom_config_path} --quiet"
    end
    let(:setup) do
      other_server.create_folder "other_public.ciao"
      other_server.send_email "other_public.ciao", **message_one
      other_server.disconnect
      create_config(**config_options)
    end

    after do
      other_server.delete_folder "other_public.ciao"
      other_server.disconnect
    end

    it "lists statistics" do
      run_command_and_stop command

      expect(last_command_started).to have_output(/other_public\.ciao\s+\|\s+1\|\s+0\|\s+0/)
    end
  end
end
