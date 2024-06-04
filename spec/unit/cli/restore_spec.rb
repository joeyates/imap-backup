require "imap/backup/cli/restore"

require "imap/backup/account"
require "imap/backup/configuration"

module Imap::Backup
  RSpec.describe CLI::Restore do
    subject { described_class.new(email, options) }

    let(:email) { "email" }
    let(:options) { {} }
    let(:account) { instance_double(Account, username: email) }
    let(:config) { instance_double(Configuration, accounts: [account]) }
    let(:restore) { instance_double(Account::Restore, run: nil) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Account::Restore).to receive(:new) { restore }
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: lambda(&:run)
    )

    it "runs restore on the account" do
      subject.run

      expect(restore).to have_received(:run)
    end

    context "when options are provided" do
      let(:options) { {delimiter: "/", prefix: "CIAO"} }

      it "passes them to the restore" do
        subject.run

        expect(Account::Restore).to have_received(:new).
          with(hash_including(delimiter: "/", prefix: "CIAO"))
      end
    end

    context "when neither an email nor a list of account names is provided" do
      let(:email) { nil }
      let(:options) { {} }

      before do
        allow(subject).to receive(:requested_accounts) { [account] }
      end

      it "runs restore on each account" do
        subject.run

        expect(restore).to have_received(:run)
      end
    end

    context "when an email and a list of account names is provided" do
      let(:email) { "email" }
      let(:options) { {accounts: "email2"} }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /Missing EMAIL parameter/)
      end
    end

    context "when just a list of account names is provided" do
      let(:email) { nil }
      let(:options) { {accounts: "email2"} }

      before do
        allow(subject).to receive(:requested_accounts) { [account] }
      end

      it "runs restore on each account" do
        subject.run

        expect(restore).to have_received(:run)
      end
    end
  end
end
