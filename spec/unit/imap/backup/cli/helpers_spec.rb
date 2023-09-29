require "imap/backup/cli/helpers"

module Imap::Backup
  class WithHelpers < Thor
    include CLI::Helpers

    def initialize(options)
      super([], options, {})
    end
  end

  RSpec.describe CLI::Helpers do
    subject { WithHelpers.new(options) }

    let(:email) { "email@example.com" }
    let(:first_account) { instance_double(Account, username: email) }
    let(:second_account) { instance_double(Account, username: "foo") }
    let(:accounts) { [first_account, second_account] }
    let(:config) { instance_double(Configuration, accounts: accounts) }
    let(:options) { {} }

    describe ".load_config" do
      let(:exists) { true }
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
          expect do
            subject.load_config(**options)
          end.to_not raise_error
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

    describe ".options" do
      let(:options) { {"foo" => 1, "bar" => 2} }
      let(:result) { subject.options }

      it "converts string keys to symbols" do
        expect(result.keys).to eq([:foo, :bar])
      end

      context "when keys have hyphens" do
        let(:options) { {"some-option" => 3} }

        it "replaces them with underscores" do
          expect(result.keys).to eq([:some_option])
        end
      end
    end

    describe ".account" do
      it "returns any account with a matching username" do
        expect(subject.account(config, email)).to eq(first_account)
      end

      context "when no match is found" do
        let(:accounts) { [second_account] }

        it "fails" do
          expect do
            subject.account(config, email)
          end.to raise_error(RuntimeError, /not a configured account/)
        end
      end
    end

    describe ".requested_accounts" do
      let(:options) { {accounts: email} }

      it "returns requested accounts" do
        expect(subject.requested_accounts(config)).to eq([first_account])
      end

      context "when no accounts are requested" do
        let(:options) { {} }

        it "returns all configured accounts" do
          expect(subject.requested_accounts(config)).to eq(accounts)
        end
      end
    end
  end
end
