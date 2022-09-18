require "imap/backup/cli/accounts"

module Imap::Backup
  describe CLI::Accounts do
    subject { described_class.new(config: config, emails: emails) }

    let(:emails) { [] }
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
    let(:config) do
      instance_double(Configuration, accounts: accounts)
    end

    describe "#each" do
      specify "calls the block with each account" do
        result = subject.map { |a| a }

        expect(result).to eq(accounts)
      end

      context "when an account list is provided" do
        let(:emails) { %w(a2@example.com) }

        specify "calls the block with each account" do
          result = subject.map { |a| a }

          expect(result).to eq([account2])
        end
      end
    end
  end
end
