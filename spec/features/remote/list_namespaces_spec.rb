require "features/helper"

RSpec.describe "imap-backup remote namespaces", :docker, type: :aruba do
  let(:account) { test_server_connection_parameters }
  let(:config_options) { {accounts: [account]} }
  let(:command) { "imap-backup remote namespaces #{account[:username]}" }

  before do
    create_config(**config_options)
  end

  it "lists namespaces" do
    run_command_and_stop command

    expect(last_command_started).to have_output(/personal\s+""\s+"\."/)
  end

  context "when JSON is requested" do
    let(:command) { "imap-backup remote namespaces #{account[:username]} --format json" }

    it "lists namespaces as JSON" do
      run_command_and_stop command

      expect(last_command_started).to have_output(/{"personal":{"prefix":"","delim":"."}/)
    end
  end
end
