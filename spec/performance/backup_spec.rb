require "features/helper"

RSpec.describe "imap-backup backup performance", type: :aruba, docker: true, performance: true do
  include_context "message-fixtures"

  let(:account_config) { test_server_connection_parameters }
  let(:email) { account_config[:username] }
  let(:folder) { "my-stuff" }
  let(:config_options) { {accounts: [account_config]} }
  let(:t_start_setup) { Time.now }
  let(:t_finish_setup) { Time.now }
  let(:t_start_run) { Time.now }
  let(:t_end_run) { Time.now }

  before do
    test_server.create_folder folder
    t_start_setup
    1.upto(1000) { test_server.send_email folder, **msg1 }
    t_finish_setup
    create_config(**config_options)
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
    puts [t_start_setup, t_finish_setup, t_start_run, t_end_run]
  end

  it "runs" do
    t_start_run
    run_command_and_stop "imap-backup backup"
    t_end_run
  end
end
