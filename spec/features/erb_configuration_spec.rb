require "features/helper"

RSpec.describe "imap-backup with ERB configuration", :container, type: :aruba do
  include_context "message-fixtures"

  let(:account) { test_server_connection_parameters }
  let(:folder) { "erb-test-folder" }
  let(:erb_config_path) { File.join(File.expand_path("~/.imap-backup"), "config.json.erb") }
  let(:erb_content) do
    <<~ERB
      {
        "accounts": [
          {
            "username": "<%= ENV['TEST_USERNAME'] %>",
            "password": "<%= ENV['TEST_PASSWORD'] %>",
            "server": "<%= ENV['TEST_SERVER'] %>",
            "local_path": "<%= ENV['TEST_LOCAL_PATH'] %>",
            "folders": ["#{folder}"],
            "connection_options": <%= ENV['TEST_CONNECTION_OPTIONS'] %>
          }
        ]
      }
    ERB
  end
  let(:command) { "imap-backup stats #{account[:username]} --erb-configuration #{erb_config_path}" }

  let!(:setup) do
    test_server.warn_about_non_default_folders
    test_server.create_folder folder
    test_server.send_email folder, **message_one
    test_server.disconnect
    
    # Set up environment variables
    ENV["TEST_USERNAME"] = account[:username]
    ENV["TEST_PASSWORD"] = account[:password]
    ENV["TEST_SERVER"] = account[:server]
    ENV["TEST_LOCAL_PATH"] = account[:local_path]
    ENV["TEST_CONNECTION_OPTIONS"] = account[:connection_options].to_json

    # Create ERB config file
    create_directory File.dirname(erb_config_path)
    File.write(erb_config_path, erb_content)
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
    File.delete(erb_config_path) if File.exist?(erb_config_path)
    ENV.delete("TEST_USERNAME")
    ENV.delete("TEST_PASSWORD")
    ENV.delete("TEST_SERVER")
    ENV.delete("TEST_LOCAL_PATH")
    ENV.delete("TEST_CONNECTION_OPTIONS")
  end

  it "processes ERB template and runs command successfully" do
    run_command_and_stop command

    expect(last_command_started).to have_output(/#{folder}\s+\|\s+1\|\s+0\|\s+0/)
  end

  context "when both --config and --erb-configuration are supplied" do
    let(:config_path) { File.join(File.expand_path("~/.imap-backup"), "config.json") }
    let(:command) do
      "imap-backup stats #{account[:username]} --config #{config_path} --erb-configuration #{erb_config_path}"
    end

    it "fails with an error" do
      run_command_and_stop command, fail_on_error: false

      expect(last_command_started).to have_output(/Cannot specify both --config and --erb-configuration/)
    end
  end

  context "when ERB template file does not exist" do
    let(:missing_erb_path) { "/tmp/nonexistent.json.erb" }
    let(:command) { "imap-backup stats #{account[:username]} --erb-configuration #{missing_erb_path}" }

    it "fails with an error" do
      run_command_and_stop command, fail_on_error: false

      expect(last_command_started).to have_output(/ERB configuration file.*not found/)
    end
  end

  context "when ERB template renders invalid JSON" do
    let(:invalid_erb_content) { "<%= 'not valid json' %>" }

    before do
      File.write(erb_config_path, invalid_erb_content)
    end

    it "fails with an error" do
      run_command_and_stop command, fail_on_error: false

      expect(last_command_started).to have_output(/ERB template rendered invalid JSON/)
    end
  end

  context "when setup command is used with --erb-configuration" do
    let(:command) { "imap-backup setup --erb-configuration #{erb_config_path}" }

    it "does not recognize the option" do
      run_command_and_stop command, fail_on_error: false

      # Thor will complain about unknown option
      expect(last_command_started).to have_output(/Unknown.*erb.*configuration|unrecognized option/i)
    end
  end
end
