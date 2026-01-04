require "imap/backup/cli/stats"

require "imap/backup/account/backup_folders"
require "imap/backup/logger"
require "imap/backup/serializer"

module Imap::Backup
  RSpec.describe CLI::Stats do
    subject { described_class.new(email, options) }

    let(:email) { "email@example.com" }
    let(:options) { {config: "/tmp/config.json"} }

    describe "#run" do
      let(:logger) { instance_double(::Logger, debug: nil) }
      let(:config) { instance_double(Configuration) }
      let(:client) { instance_double(Object) }
      let(:account) do
        instance_double(Account, client: client, local_path: "/tmp/local")
      end
      let(:backup_folders) { instance_double(Account::BackupFolders) }
      let(:existing_folder) do
        instance_double(
          Account::Folder,
          exist?: true,
          name: "INBOX",
          uids: remote_uids
        )
      end
      let(:missing_folder) do
        instance_double(
          Account::Folder,
          exist?: false,
          name: "Archive",
          uids: []
        )
      end
      let(:folders) { [existing_folder, missing_folder] }
      let(:local_uids) { [2, 3, 4] }
      let(:remote_uids) { [1, 2, 3] }
      let(:serializer) { instance_double(Serializer, uids: local_uids) }
      let(:expected_stats) do
        [
          {
            folder: "INBOX",
            remote: 1,
            both: 2,
            local: 1
          }
        ]
      end

      before do
        allow(Logger).to receive(:logger) { logger }
        allow(subject).to receive(:load_config).with(**options) { config }
        allow(subject).to receive(:account).with(config, email) { account }
        allow(Account::BackupFolders).to receive(:new).
          with(client: client, account: account) { backup_folders }
        allow(backup_folders).to receive(:map) do |&block|
          folders.map { |folder| block.call(folder) }
        end
        allow(Serializer).to receive(:new).
          with(account.local_path, existing_folder.name) { serializer }
      end

      context "when format is json" do
        let(:options) { {format: "json"} }
        let(:output_lines) { [] }

        before do
          allow(Kernel).to receive(:puts) { |line| output_lines << line }
        end

        it "prints the folder statistics as JSON" do
          subject.run

          expect(output_lines).to eq([expected_stats.to_json])
        end
      end

      context "when format is text" do
        let(:options) { {config: "/tmp/config.json"} }
        let(:output_lines) { [] }

        before do
          allow(Kernel).to receive(:puts) { |line| output_lines << line }
        end

        it "prints the header and formatted rows" do
          subject.run

          expected_output = [
            "folder              |remote  |both    |local   \n" \
            "--------------------|--------|--------|--------",
            "INBOX               |       1|       2|       1"
          ]

          expect(output_lines).to eq(expected_output)
        end
      end
    end
  end
end
