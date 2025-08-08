require "imap/backup/cli/transfer"

require "net/imap"
require "imap/backup/account/folder"
require "imap/backup/serializer"

module Imap::Backup
  RSpec.describe CLI::Transfer do
    subject { described_class.new(action, source, destination, options) }

    let(:action) { :migrate }
    let(:source) { "source" }
    let(:destination) { "destination" }
    let(:options) { {} }
    let(:config) do
      instance_double(Configuration, accounts: [source_account, destination_account])
    end
    let(:source_account) do
      instance_double(
        Account, "Source Account",
        local_path: "account1_path",
        mirror_mode: source_mirror_mode,
        username: "source",
        available_for_migration?: true
      )
    end
    let(:source_mirror_mode) { true }
    let(:destination_account) do
      instance_double(
        Account, "Destination Account",
        username: "destination",
        available_for_migration?: true
      )
    end
    let(:serializer) { instance_double(Serializer) }
    let(:folder) { instance_double(Account::Folder) }
    let(:migrator) { instance_double(Migrator, run: nil) }
    let(:mirror) { instance_double(Mirror, run: nil) }
    let(:backup) { instance_double(CLI::Backup, "backup_1", run: nil) }
    let(:folder_mapper) { instance_double(Account::FolderMapper) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(CLI::Backup).to receive(:new) { backup }
      allow(Migrator).to receive(:new) { migrator }
      allow(Mirror).to receive(:new) { mirror }
      allow(Account::FolderMapper).to receive(:new) { folder_mapper }
      allow(folder_mapper).to receive(:each).and_yield(serializer, folder)
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: lambda(&:run)
    )

    context "when in migrate mode" do
      it "migrates each folder" do
        subject.run

        expect(migrator).to have_received(:run)
      end
    end

    context "when in copy mode" do
      let(:action) { :copy }
      let(:backup) { instance_double(CLI::Backup, "backup_1", run: nil) }

      it "runs backup on the source" do
        subject.run

        expect(backup).to have_received(:run)
      end

      it "mirrors each folder" do
        subject.run

        expect(mirror).to have_received(:run)
      end

      it "instructs the mirror class to not reset the destination folder" do
        subject.run

        expect(Mirror).to have_received(:new).with(anything, anything, reset: false) { mirror }
      end
    end

    context "when in mirror mode" do
      let(:action) { :mirror }
      let(:backup) { instance_double(CLI::Backup, "backup_1", run: nil) }

      context "when the source account is not in mirror mode" do
        let(:source_mirror_mode) { false }

        before { allow(Logger.logger).to receive(:warn) }

        it "warns" do
          subject.run

          expect(Logger.logger).to have_received(:warn).with(/not set up/)
        end
      end

      it "runs backup on the source" do
        subject.run

        expect(backup).to have_received(:run)
      end

      it "mirrors each folder" do
        subject.run

        expect(mirror).to have_received(:run)
      end

      it "instructs the mirror class to reset the destination folder" do
        subject.run

        expect(Mirror).to have_received(:new).with(anything, anything, reset: true) { mirror }
      end
    end

    context "when source and destination emails are the same" do
      let(:destination) { "source" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /cannot be the same/)
      end
    end

    context "when the source account is not found" do
      let(:source) { "unknown" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /does not exist/)
      end
    end

    context "when the destination account is not found" do
      let(:destination) { "unknown" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /does not exist/)
      end
    end

    %i[
      automatic_namespaces
      config
      destination_delimiter
      destination_prefix
      reset
      source_delimiter
      source_prefix
    ].each do |option|
      it "accepts a #{option} option" do
        opts = options.merge(option => "foo")
        expect do
          described_class.new(:migrate, source, destination, **opts)
        end.to_not raise_error
      end
    end

    context "when the automatic_namespaces option is given" do
      let(:options) { {automatic_namespaces: true} }
      let(:source_client) do
        instance_double(
          Client::Default, "Source Client",
          namespace: source_namespace
        )
      end
      let(:source_namespace) do
        Net::IMAP::Namespaces.new(
          [
            Net::IMAP::Namespace.new("source_prefix", "%")
          ]
        )
      end
      let(:destination_client) do
        instance_double(
          Client::Default, "Destination Client",
          namespace: destination_namespace
        )
      end
      let(:destination_namespace) do
        Net::IMAP::Namespaces.new(
          [
            Net::IMAP::Namespace.new("destination_prefix", "@")
          ]
        )
      end

      before do
        allow(source_account).to receive(:client) { source_client }
        allow(destination_account).to receive(:client) { destination_client }
      end

      it "uses the values from the servers" do
        subject.run

        expect(Account::FolderMapper).to have_received(:new).
          with(
            hash_including(
              {
                source_prefix: "source_prefix",
                source_delimiter: "%",
                destination_prefix: "destination_prefix",
                destination_delimiter: "@"
              }
            )
          )
      end

      %i(source_prefix source_delimiter destination_prefix destination_delimiter).
        each do |parameter|
        context "when a #{parameter} is given" do
          let(:options) { {:automatic_namespaces => true, parameter => "x"} }

          it "fails" do
            expect do
              subject.run
            end.to raise_error(RuntimeError, /incompatible/)
          end
        end
      end
    end

    context "when the automatic_namespaces option is not given" do
      [
        [:source_prefix, ""],
        [:source_delimiter, "/"],
        [:destination_prefix, ""],
        [:destination_delimiter, "/"]
      ].each do |parameter, default|
        context "when no #{parameter} is supplied" do
          it "defaults to '#{default}'" do
            subject.run

            expect(Account::FolderMapper).to have_received(:new).
              with(hash_including({parameter => default}))
          end
        end
      end

      %i(source_prefix source_delimiter destination_prefix destination_delimiter).
        each do |parameter|
        context "when #{parameter} is supplied" do
          let(:options) { {parameter => "x"} }

          it "uses the supplied value" do
            subject.run

            expect(Account::FolderMapper).to have_received(:new).
              with(hash_including({parameter => "x"}))
          end
        end
      end
    end

    context "when accounts have invalid status for migration" do
      context "when source account is offline" do
        let(:source_account) do
          instance_double(
            Account, "Source Account",
            local_path: "account1_path",
            mirror_mode: source_mirror_mode,
            username: "source",
            available_for_migration?: false,
            status: "offline"
          )
        end

        it "raises an error" do
          expect do
            subject.run
          end.to raise_error(RuntimeError, /source.*not available for migration.*offline/)
        end
      end

      context "when destination account is offline" do
        let(:destination_account) do
          instance_double(
            Account, "Destination Account",
            username: "destination",
            available_for_migration?: false,
            status: "offline"
          )
        end

        it "raises an error" do
          expect do
            subject.run
          end.to raise_error(RuntimeError, /destination.*not available for migration.*offline/)
        end
      end
    end
  end
end
