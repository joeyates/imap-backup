require "imap/backup/cli/helpers"

require "imap/backup/account"

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
    let(:first_account) { instance_double(Account, username: email, password: "foo") }
    let(:second_account) { instance_double(Account, username: "foo", password: "bar") }
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

    describe ".env_vars" do
      let(:env_account1) { instance_double(Account, password: "$FOO") }
      let(:env_account2) { instance_double(Account, password: "$BAR") }
      let(:env_accounts) { [env_account1, env_account2] }
      let(:env_cfg) { instance_double(Configuration, accounts: env_accounts) }
      let(:options) { {env: "env"} }
      let(:console) { double("IO::Console") }

      before do
        allow(env_account1).to receive(:password=)
        allow(ENV).to receive(:key?).with("FOO").and_return(true)
        allow(ENV).to receive("[]").with("FOO").and_return("bar")

        allow(env_account2).to receive(:password=)
        allow(ENV).to receive(:key?).with("BAR").and_return(false)
        allow(IO).to receive(:console).and_return(console)
        allow(console).to receive(:noecho).and_yield(double("IO", gets: "pwd"))
        allow($stdout).to receive(:write).and_return(nil)
      end

      it "replaces environment variables for password fields" do
        subject.assign_env_vars(env_cfg, options)

        expect(env_account1).to have_received(:password=).with("bar")
      end

      context "when the environment variable is not set" do
        it "prompt the user to enter the password" do
          subject.assign_env_vars(env_cfg, options)

          expect($stdout).to have_received(:write).with("\nEnter your password: ")
          expect(env_account2).to have_received(:password=).with("pwd")
        end
      end

      context "when there is no environment variable in configuration" do
        it "returns the configuration as is" do
          expect(subject.assign_env_vars(config, options)).to eq(config)
        end
      end

      context "when the `env` command option is not set" do
        let(:options) { {} }

        it "returns the configuration as is" do
          expect(subject.assign_env_vars(config, options)).to eq(config)
          expect(subject.assign_env_vars(env_cfg, options)).to eq(env_cfg)
        end
      end
    end
  end
end
