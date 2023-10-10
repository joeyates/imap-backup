require "features/helper"

RSpec.describe "imap-backup direct", :docker, type: :aruba do
  include_context "message-fixtures"

  let(:folder) { "my-stuff" }
  let(:messages_as_mbox) do
    to_mbox_entry(**message_one) + to_mbox_entry(**message_two)
  end
  let!(:pre) do
    test_server.delete_folder folder
  end
  let!(:setup) do
    test_server.create_folder folder
    test_server.send_email folder, **message_one
    test_server.send_email folder, **message_two
  end
  let(:account) { test_server_connection_parameters }
  let(:connection_options) { account[:connection_options].to_json }
  let(:command) do
    "imap-backup direct " \
      "--username #{account[:username]} " \
      "--password #{account[:password]} " \
      "--server #{account[:server]} " \
      "--path #{account[:local_path]} " \
      "--connection-options '#{connection_options}'"
  end

  it "downloads messages" do
    run_command_and_stop command

    actual = mbox_content(account[:username], folder, local_path: account[:local_path])
    expect(actual).to eq(messages_as_mbox)
  end
end
