require "imap/backup/cli/backup"

require "imap/backup/account"
require "imap/backup/configuration"

module Imap::Backup
  RSpec.describe CLI::Backup do
    subject { described_class.new({}) }

    let(:account) { instance_double(Account, username: "me@example.com", available_for_backup?: true) }
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
      let(:active_account) { instance_double(Account, username: "active@example.com", available_for_backup?: true) }
      let(:archived_account) { instance_double(Account, username: "archived@example.com", available_for_backup?: false) }
      let(:offline_account) { instance_double(Account, username: "offline@example.com", available_for_backup?: false) }

      before do
        allow(subject).to receive(:requested_accounts) { [active_account, archived_account, offline_account] }
      end

      it "only runs backup for accounts available for backup" do
        subject.run

        expect(Account::Backup).to have_received(:new).with(account: active_account, refresh: false)
        expect(Account::Backup).not_to have_received(:new).with(account: archived_account, refresh: anything)
        expect(Account::Backup).not_to have_received(:new).with(account: offline_account, refresh: anything)
      end
    end
  end
end
