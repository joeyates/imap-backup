require "imap/backup/cli/backup"

require "ostruct"

require "imap/backup/account"
require "imap/backup/configuration"
require "imap/backup/lockfile"

module Imap::Backup
  RSpec.describe CLI::Backup, :silence_logging do
    subject { described_class.new(options) }

    let(:options) { {} }
    let(:account) do
      instance_double(Account, username: "me@example.com", available_for_backup?: true)
    end
    let(:backup) { instance_double(Account::Backup, "backup", run: nil) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Account::Backup).to receive(:new) { backup }
      allow(subject).to receive(:requested_accounts) { [account] }
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: lambda(&:run)
    )

    it "runs the backup for each connection" do
      subject.run

      expect(backup).to have_received(:run)
    end

    context "when one connection fails" do
      let(:account2) { instance_double(Account, "account2", available_for_backup?: true) }

      before do
        outcomes = [-> { raise "Foo" }, -> { true }]
        allow(backup).to receive(:run) { outcomes.shift.call }

        allow(subject).to receive(:requested_accounts) { [account, account2] }
      end

      it "runs other backups" do
        # rubocop:disable Lint/SuppressedException
        begin
          subject.run
        rescue SystemExit
        end
        # rubocop:enable Lint/SuppressedException

        expect(backup).to have_received(:run).twice
      end

      it "exits with an error" do
        expect do
          subject.run
        end.to raise_exception(SystemExit)
      end
    end

    context "when accounts have different statuses" do
      let(:active_account) do
        instance_double(Account, username: "active@example.com", available_for_backup?: true)
      end
      let(:archived_account) do
        instance_double(Account, username: "archived@example.com", available_for_backup?: false)
      end
      let(:offline_account) do
        instance_double(Account, username: "offline@example.com", available_for_backup?: false)
      end

      before do
        allow(subject).to receive(:requested_accounts) {
          [active_account, archived_account, offline_account]
        }
      end

      it "only runs backup for accounts available for backup" do
        subject.run

        expect(Account::Backup).to have_received(:new).with(account: active_account, refresh: false)
        expect(Account::Backup).not_to have_received(:new).
          with(account: archived_account, refresh: anything)
        expect(Account::Backup).not_to have_received(:new).
          with(account: offline_account, refresh: anything)
      end
    end

    context "when no accounts are available" do
      before do
        allow(Logger.logger).to receive(:warn)
        allow(subject).to receive(:requested_accounts) { [] }
      end

      it "warns and exits early" do
        subject.run

        expect(Logger.logger).
          to have_received(:warn).
          with("No matching accounts found to backup")
        expect(Account::Backup).to_not have_received(:new)
      end
    end

    context "when the refresh option is supplied" do
      let(:options) { {refresh: true} }

      it "passes the refresh flag to the account backup" do
        subject.run

        expect(Account::Backup).to have_received(:new).
          with(account: account, refresh: true)
      end
    end

    context "when the IMAP server rejects the request" do
      let(:imap_error) do
        Net::IMAP::NoResponseError.new(
          OpenStruct.new({data: OpenStruct.new({text: "Temporary failure"})})
        )
      end

      before do
        allow(backup).to receive(:run).and_raise(imap_error)
      end

      it "exits with a custom failure code" do
        block = -> { subject.run }

        expect { block.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(111)
        end
      end
    end

    context "when the account is locked elsewhere" do
      before do
        allow(backup).to receive(:run).and_raise(Lockfile::LockfileExistsError.new("locked"))
      end

      it "exits with the lock failure code" do
        block = -> { subject.run }

        expect { block.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(112)
        end
      end
    end
  end
end
