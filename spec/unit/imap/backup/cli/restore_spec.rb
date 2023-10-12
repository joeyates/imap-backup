require "imap/backup/cli/restore"

require "imap/backup/account"
require "imap/backup/configuration"

module Imap::Backup
  RSpec.describe CLI::Restore do
    subject { described_class.new(email, options) }

    let(:email) { "email" }
    let(:options) { {} }
    let(:account) { instance_double(Account, username: email, restore: nil) }
    let(:config) { instance_double(Configuration, accounts: [account]) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: ->(subject) { subject.run }
    )

    describe "#run" do
      context "when an email is provided" do
        it "runs restore on the account" do
          subject.run

          expect(account).to have_received(:restore)
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

          expect(account).to have_received(:restore)
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

          expect(account).to have_received(:restore)
        end
      end
    end
  end
end
