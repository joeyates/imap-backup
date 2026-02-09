require "imap/backup/cli/helpers"

require "imap/backup/account"
require "imap/backup/translator"

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
        Translator.new.setup

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

      context "when erb_configuration is supplied" do
        let(:erb_path) { "/tmp/config.json.erb" }
        let(:erb_content) { '{"accounts": [{"username": "test@example.com"}]}' }
        let(:rendered_json) { '{"accounts": [{"username": "test@example.com"}]}' }
        let(:options) { {erb_configuration: erb_path} }
        let(:temp_file) do
          instance_double(Tempfile, write: nil, flush: nil, close: nil, path: "/tmp/tempfile.json",
                                    unlink: nil)
        end
        let(:erb_config) { instance_double(Configuration, accounts: []) }

        before do
          allow(File).to receive(:exist?).with(erb_path) { true }
          allow(File).to receive(:read).with(erb_path) { erb_content }
          allow(Tempfile).to receive(:new) { temp_file }
          allow(Configuration).
            to receive(:new).
              with(path: temp_file.path) { erb_config }
        end

        it "processes the ERB template" do
          expect(subject.load_config(**options)).to eq(erb_config)
        end

        it "cleans up the temporary file" do
          subject.load_config(**options)
          expect(temp_file).to have_received(:unlink)
        end

        context "when the ERB file does not exist" do
          before do
            allow(File).to receive(:exist?).with(erb_path) { false }
          end

          it "raises an error" do
            expect do
              subject.load_config(**options)
            end.to raise_error(ConfigurationNotFound, /ERB configuration file.*not found/)
          end
        end

        context "when ERB template has syntax errors" do
          let(:erb_content) { "<% if %>" }

          it "raises an error" do
            expect do
              subject.load_config(**options)
            end.to raise_error(/ERB template has syntax error/)
          end
        end

        context "when ERB template renders invalid JSON" do
          let(:erb_content) { '<%= "invalid json" %>' }

          it "raises an error" do
            expect do
              subject.load_config(**options)
            end.to raise_error(/ERB template rendered invalid JSON/)
          end
        end

        context "when ERB template uses environment variables" do
          let(:erb_content) { %q({"accounts": [{"password": "<%= ENV['TEST_PASSWORD'] %>"}]}) }

          before do
            ENV["TEST_PASSWORD"] = "secret123"
          end

          after do
            ENV.delete("TEST_PASSWORD")
          end

          it "substitutes environment variables" do
            subject.load_config(**options)
            expect(temp_file).to have_received(:write).with(/"password": "secret123"/)
          end
        end

        context "when ERB has Ruby runtime errors" do
          let(:erb_content) { "<%= 1 / 0 %>" }

          it "raises an error" do
            expect do
              subject.load_config(**options)
            end.to raise_error(/Error processing ERB template/)
          end
        end

        context "when both config and erb_configuration are supplied" do
          let(:options) { {config: "/tmp/config.json", erb_configuration: erb_path} }

          it "raises an error" do
            expect do
              subject.load_config(**options)
            end.to raise_error(/Cannot specify both --config and --erb-configuration/)
          end
        end

        context "when the temporary file cannot be created" do
          before do
            allow(Tempfile).to receive(:new) { nil }
          end

          it "skips unlinking the file" do
            expect do
              subject.load_config(**options)
            end.to raise_error(NoMethodError)
          end
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

      context "when keys are already symbols" do
        let(:options) { {foo: 1} }

        it "leaves them untouched" do
          expect(result[:foo]).to eq(1)
        end
      end

      context "when the superclass already provides symbol keys" do
        let(:symbol_helper_base) do
          Class.new do
            def initialize(raw_options)
              @raw_options = raw_options
            end

            def options
              @raw_options
            end
          end
        end
        let(:symbol_helper_class) do
          options_helper = instance_double(Imap::Backup::CLI::Options, define_options: nil)
          allow(Imap::Backup::CLI::Options).to receive(:new) { options_helper }

          Class.new(symbol_helper_base) do
            include CLI::Helpers
          end
        end
        let(:symbol_subject) { symbol_helper_class.new(foo: 1) }

        it "does not alter symbol keys" do
          expect(symbol_subject.options[:foo]).to eq(1)
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
