require "imap/backup/cli/accounts"

module Imap::Backup
  describe CLI::Accounts do
    subject { described_class.new(required_accounts) }

    let(:required_accounts) { [] }
    let(:accounts) { [account1, account2] }
    let(:account1) do
      instance_double(
        Account,
        username: "a1@example.com"
      )
    end
    let(:account2) do
      instance_double(
        Account,
        username: "a2@example.com"
      )
    end
    let(:store) do
      instance_double(Configuration, accounts: accounts)
    end
    let(:exists) { true }

    before do
      allow(Configuration).to receive(:new) { store }
      allow(Configuration).
        to receive(:exist?) { exists }
    end

    describe "#each" do
      specify "calls the block with each account" do
        result = subject.map { |a| a }

        expect(result).to eq(accounts)
      end

      context "when the configuration file is missing" do
        let(:exists) { false }

        it "fails" do
          expect do
            subject.each {}
          end.to raise_error(ConfigurationNotFound, /not found/)
        end
      end

      context "when an account list is provided" do
        let(:required_accounts) { %w(a2@example.com) }

        specify "calls the block with each account" do
          result = subject.map { |a| a }

          expect(result).to eq([account2])
        end
      end
    end
  end
end
