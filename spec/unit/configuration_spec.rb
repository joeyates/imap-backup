require "imap/backup/configuration"

# rubocop:disable RSpec/PredicateMatcher

module Imap::Backup
  RSpec.describe Configuration do
    let(:directory) { "/base/path" }
    let(:file_path) { File.join(directory, "/config.json") }
    let(:file_exists) { true }
    let(:directory_exists) { true }
    let(:configuration) { {accounts: accounts.map(&:to_h)}.to_json }
    let(:accounts) do
      [
        Account.new({username: "username1", password: "password1"}),
        Account.new({username: "username2", password: "password2"})
      ]
    end
    let(:permission_checker) { instance_double(Serializer::PermissionChecker, run: nil) }

    before do
      stub_const(
        "Imap::Backup::Configuration::CONFIGURATION_DIRECTORY", directory
      )
      allow(File).to receive(:directory?).and_call_original
      allow(File).to receive(:directory?).with(directory) { directory_exists }
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(file_path) { file_exists }
      allow(Serializer::PermissionChecker).to receive(:new) { permission_checker }
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(file_path) { configuration }
      allow(FileUtils).to receive(:chmod)
      allow(FileUtils).to receive(:mkdir_p)
    end

    describe ".exist?" do
      [true, false].each do |exists|
        state = exists ? "exists" : "doesn't exist"
        context "when the file #{state}" do
          let(:file_exists) { exists }

          it "returns #{exists}" do
            expect(described_class.exist?).to eq(file_exists)
          end
        end
      end
    end

    describe "#path" do
      it "is the directory containing the configuration file" do
        expect(subject.path).to eq(directory)
      end
    end

    describe "#modified?" do
      context "with modified accounts" do
        before { subject.accounts[0].username = "changed" }

        it "is true" do
          expect(subject.modified?).to be_truthy
        end
      end

      context "with accounts flagged 'delete'" do
        before { subject.accounts[0].mark_for_deletion }

        it "is true" do
          expect(subject.modified?).to be_truthy
        end
      end

      context "without accounts flagged 'modified'" do
        it "is false" do
          expect(subject.modified?).to be_falsey
        end
      end
    end

    describe "#save" do
      let(:directory_exists) { false }
      let(:file) { instance_double(File, write: nil) }

      before do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(file_path, "w").and_yield(file)
      end

      it "creates the config directory" do
        expect(FileUtils).to receive(:mkdir_p).with(directory)

        subject.save
      end

      it "saves the configuration" do
        expect(file).to receive(:write).with(/^\{/)

        subject.save
      end

      it "saves the version" do
        expect(file).to receive(:write).with(/"version": "[\d\.]+"/)

        subject.save
      end

      it "serializes all Account data" do
        serialized = nil
        allow(file).to receive(:write) { |data| serialized = data }

        subject.save

        parsed = JSON.parse(serialized, symbolize_names: true)

        expect(parsed[:accounts].first).to eq(
          {
            username: "username1", password: "password1",
            multi_fetch_size: 1
          }
        )
      end

      context "when accounts are to be deleted" do
        it "does not save them" do
          subject.accounts[0].mark_for_deletion

          subject.save

          expect(file).to have_received(:write).with(/"username2"/)
          expect(file).to_not have_received(:write).with(/"username1"/)
        end
      end

      context "when file permissions are too open" do
        context "when on UNIX" do
          before do
            allow(OS).to receive(:windows?) { false }
          end

          it "sets them to 0600" do
            expect(FileUtils).to receive(:chmod).with(0o600, file_path)

            subject.save
          end
        end
      end

      context "when the configuration file is missing" do
        let(:file_exists) { false }

        it "doesn't fail" do
          expect do
            subject.save
          end.to_not raise_error
        end
      end

      context "when on UNIX" do
        before do
          allow(OS).to receive(:windows?) { false }
        end

        context "when the config file permissions are too lax" do
          let(:file_exists) { true }

          before do
            allow(permission_checker).to receive(:run).and_raise("Error")
          end

          it "fails" do
            expect do
              subject.save
            end.to raise_error(RuntimeError, "Error")
          end
        end
      end
    end

    describe "#download_strategy" do
      context "when the configuration file is missing" do
        let(:file_exists) { false }

        it "defaults to delayed metadata" do
          expect(subject.download_strategy).to eq "delay_metadata"
        end
      end
    end

    context "when a folders are stored as Hashes" do
      let(:file) { instance_double(File, write: nil) }
      let(:configuration) do
        {accounts: [{username: "account", password: "ciao", folders: [{name: "foo"}]}]}.to_json
      end

      before do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(file_path, "w").and_yield(file)
      end

      it "changes account folders from an array of hashes to an array" do
        subject.save

        expect(file).to have_received(:write).
          with(
            /
            "folders":\s+\[\s+
              "foo"\s+
            \]
            /x
          )
      end
    end
  end
end

# rubocop:enable RSpec/PredicateMatcher
