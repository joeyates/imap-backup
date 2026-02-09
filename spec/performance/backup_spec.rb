require "json"
require "features/helper"
require "imap/backup/configuration"

# rubocop:disable RSpec/BeforeAfterAll

# Use exponentially-spaced values so we get an even plot on a logarithmic scale
COUNTS = 0.upto(12).map { |p| (Math::E ** p).round }
RUNS = 4

RSpec.describe "imap-backup backup performance", :container, :performance, type: :aruba do
  let(:results) do
    COUNTS.reduce({}, COUNTS) do |memo, count|
      memo[count] = []
      memo
    end
  end

  before(:all) do
    test_server.folders.each do |folder|
      next if !folder.start_with?("bulk-")

      test_server.delete_folder folder
    end
    COUNTS.each do |count|
      folder = "bulk-#{count}"
      test_server.create_folder folder
      message = {from: "address@example.org", subject: "Test 1", body: "body 1\nHi"}
      test_server.send_multiple_emails folder, count: count, batch: 1000, **message
    end
  end

  COUNTS.each do |message_count|
    context "with #{message_count} emails" do
      Imap::Backup::Configuration::DOWNLOAD_STRATEGIES.each do |strategy|
        context "with #{strategy} download strategy" do
          1.upto(RUNS) do |run|
            context "with run #{run}" do
              let(:account_config) do
                test_server_connection_parameters.merge(
                  folders: [folder],
                  multi_fetch_size: multi_fetch_size
                )
              end
              let(:multi_fetch_size) { 25 }
              let(:folder) { "bulk-#{message_count}" }
              let(:config_options) do
                {accounts: [account_config], download_strategy: strategy}
              end
              let(:t_start_run) { Time.now }
              let(:t_finish_run) { Time.now }

              before do
                create_config(**config_options)
              end

              after do
                test_server.disconnect
              end

              specify "time" do
                t_start_run
                run_command_and_stop "imap-backup backup"
                t_finish_run
                time_taken = t_finish_run - t_start_run
                count_runs = results[message_count]
                count_runs[strategy] ||= []
                count_runs[strategy] << time_taken
                email = account_config[:username]
                metadata = imap_parsed(email, folder)
                expect(metadata[:messages].count).to eq(message_count)
              end
            end
          end
        end
      end
    end
  end

  after(:all) do
    test_server.folders.each do |folder|
      next if !folder.start_with?("bulk-")

      test_server.delete_folder folder
    end
    test_server.disconnect
    puts results.to_json
  end
end

# rubocop:enable RSpec/BeforeAfterAll
