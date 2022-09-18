require "imap/backup/cli/helpers"

module Imap::Backup
  class WithHelpers
    include CLI::Helpers
  end

  RSpec.describe CLI::Helpers do
    subject { WithHelpers.new }

    let(:email) { "email@example.com" }
    let(:account1) { instance_double(Account, username: email, connection: "c1") }
    let(:account2) { instance_double(Account, username: "foo", connection: "c2") }
    let(:accounts) { [account1, account2] }
    let(:config) { instance_double(Configuration, accounts: accounts) }

    describe ".load_config" do
      let(:exists) { true }
      let(:options) { {} }
      let(:params) { {path: nil} }
      let(:config) { "Configuration" }

      before do
        allow(Configuration).to receive(:new).with(params) { config }
        allow(Configuration).to receive(:exist?) { exists }
      end

      it "returns the configuration" do
        expect(subject.load_config).to eq(config)
      end

      context "when a config path is supplied" do
        let(:options) { {config: "foo"} }
        let(:params) { {path: "foo"} }

        it "loads che configuration for that path" do
          subject.load_config(**options)
        end
      end

      context "when the configuration file is missing" do
        let(:exists) { false }

        it "fails" do
          expect do
            subject.load_config
          end.to raise_error(ConfigurationNotFound, /not found/)
        end
      end
    end

    describe ".symbolized" do
      let(:arguments) { {"foo" => 1, "bar" => 2} }
      let(:result) { subject.symbolized(arguments) }

      it "converts string keys to symbols" do
        expect(result.keys).to eq([:foo, :bar])
      end

      context "when keys have hyphens" do
        let(:arguments) { {"some-option" => 3} }

        it "replaces them with underscores" do
          expect(result.keys).to eq([:some_option])
        end
      end
    end

    describe ".account" do
      it "returns any account with a matching username" do
        expect(subject.account(config, email)).to eq(account1)
      end

      context "when no match is found" do
        let(:accounts) { [account2] }

        it "fails" do
          expect do
            subject.account(config, email)
          end.to raise_error(RuntimeError, /not a configured account/)
        end
      end
    end

    describe ".connection" do
      it "returns a connection" do
        result = subject.connection(config, email)

        expect(result).to be_a(Account::Connection)
      end

      it "returns the connection for any account with a matching username" do
        result = subject.connection(config, email)

        expect(result.account).to eq(account1)
      end
    end

    describe ".each_connection" do
      it "yields each connection" do
        expect { |b| subject.each_connection(config, [email, "foo"], &b) }.
          to yield_successive_args("c1", "c2")
      end
    end
  end
end
