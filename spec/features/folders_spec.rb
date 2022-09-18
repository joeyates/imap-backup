require "features/helper"
require "imap/backup/cli/folders"

RSpec.describe "folders", type: :aruba, docker: true do
  let(:account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [account]} }

  let!(:setup) do
    create_config(**config_options)
  end

  it "lists account folders" do
    run_command_and_stop "imap-backup folders"

    expect(last_command_started).to have_output(/^\tINBOX$/)
  end

  context "when a config path is supplied" do
    let(:account) { other_server_connection_parameters }
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }

    let!(:setup) do
      create_config(**config_options)
      other_server.create_folder "foo"
    end

    it "lists configured accounts' folders" do
      run_command_and_stop "imap-backup folders --config #{custom_config_path}"

      expect(last_command_started).to have_output(/^\tfoo$/)
    end
  end
end
