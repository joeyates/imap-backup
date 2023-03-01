require "features/helper"

RSpec.describe "imap-backup local show", type: :aruba do
  include_context "message-fixtures"

  let(:email) { account[:username] }
  let(:account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [account]} }
  let!(:setup) do
    create_config(**config_options)
    append_local email: account[:username], folder: "my_folder", **msg1, uid: 99
  end

  it "shows the email" do
    run_command_and_stop "imap-backup local show #{email} my_folder 99"

    expect(last_command_started).to have_output(to_serialized(**msg1))
  end

  context "when JSON is requested" do
    it "shows the email" do
      run_command_and_stop "imap-backup local show #{email} my_folder 99 --format json"

      expected = /"body":"#{to_serialized(**msg1)}\n"/
      expect(last_command_started).to have_output(expected)
    end
  end

  context "when a config path is supplied" do
    let(:account) { other_server_connection_parameters }
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {path: custom_config_path, accounts: [account]} }
    let!(:setup) do
      create_config(**config_options)
      append_local(
        configuration_path: custom_config_path,
        email: account[:username],
        folder: "my_folder",
        **msg1,
        uid: 99
      )
    end
    let(:command) { "imap-backup local show #{email} --config #{custom_config_path}" }

    it "shows emails correctly" do
      run_command_and_stop(
        "imap-backup local show #{email} my_folder 99 --config #{custom_config_path}"
      )

      expect(last_command_started).to have_output(to_serialized(**msg1))
    end
  end
end
