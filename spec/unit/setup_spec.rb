require "imap/backup/setup"
require "imap/backup/translator"

module Imap::Backup
  RSpec.describe Setup do
    include HighLineTestHelpers

    subject { described_class.new(config: config) }

    let(:normal_account) do
      instance_double(
        Account,
        username: "account@example.com",
        marked_for_deletion?: false,
        modified?: false
      )
    end
    let(:modified_account) do
      instance_double(
        Account,
        username: "modified@example.com",
        marked_for_deletion?: false,
        modified?: true
      )
    end
    let(:deleted_account) do
      instance_double(
        Account,
        username: "delete@example.com",
        marked_for_deletion?: true,
        modified?: false
      )
    end
    let(:accounts) { [normal_account] }
    let(:config) do
      instance_double(
        Configuration,
        accounts: accounts,
        path: "/base/path",
        save: nil,
        modified?: config_modified,
        download_strategy_modified?: download_strategy_modified
      )
    end
    let(:config_modified) { false }
    let(:download_strategy_modified) { false }
    let!(:highline_streams) { prepare_highline }
    let(:input) { highline_streams[0] }
    let(:output) { highline_streams[1] }
    let(:gmail_imap_server) { "imap.gmail.com" }

    describe "#run" do
      before do
        Translator.new.setup
        allow(Logger).to receive(:setup_logging)
        allow(input).to receive(:eof?) { false }
        allow(input).to receive(:gets) { "q\n" }
        allow(Kernel).to receive(:system)
      end

      describe "main menu" do
        context "when changes have not been made" do
          before { subject.run }

          ["add account", "quit"].each do |choice|
            it "includes #{choice}" do
              expect(output.string).to include(choice)
            end
          end
        end

        context "when changes have been made" do
          let(:config_modified) { true }

          before do
            allow(input).to receive(:gets) { "exit\n" }
            subject.run
          end

          ["save and exit", "exit without saving"].each do |choice|
            it "includes '#{choice}'" do
              expect(output.string).to include(choice)
            end
          end
        end

        context "when the download strategy has been changed" do
          let(:download_strategy_modified) { true }

          before { subject.run }

          it "indicates the state" do
            expect(output.string).to match(/modify global options \*/)
          end
        end
      end

      it "clears the screen" do
        expect(Kernel).to receive(:system).with("clear")

        subject.run
      end

      describe "listing" do
        let(:accounts) { [normal_account, modified_account, deleted_account] }

        before { subject.run }

        describe "normal accounts" do
          it "are listed" do
            expect(output.string).to match(/account@example.com/)
          end
        end

        describe "modified accounts" do
          it "are flagged" do
            expect(output.string).to match(/modified@example.com \*/)
          end
        end

        describe "deleted accounts" do
          it "are hidden" do
            expect(output.string).to_not match(/delete@example.com/)
          end
        end
      end

      context "when modifying global options" do
        let(:global_options) { instance_double(Setup::GlobalOptions, run: nil) }

        before do
          allow(input).to receive(:gets).and_return("3\n", "q\n")
          allow(Setup::GlobalOptions).
            to receive(:new).with(config: config) { global_options }
        end

        it "runs the global options flow" do
          subject.run

          expect(global_options).to have_received(:run)
        end
      end

      context "when editing accounts" do
        let(:account) do
          instance_double(Setup::Account, run: nil)
        end
        let(:config_modified) { true }

        before do
          allow(input).to receive(:gets).and_return("1\n", "exit\n")
          allow(Setup::Asker).to receive(:email).
            with(no_args) { "new@example.com" }
          allow(Setup::Account).to receive(:new).
            with(config, normal_account, anything) { account }
        end

        it "edits the account" do
          expect(account).to receive(:run)

          subject.run
        end
      end

      context "when adding accounts" do
        let(:setup_account) { instance_double(Setup::Account, run: nil) }
        let(:config_modified) { true }
        let(:added_email) { "new@example.com" }
        let(:local_path) { "/base/path/new_example.com" }
        let(:new_account) do
          instance_double(Account, "server=": nil, "reset_seen_flags_after_fetch=": nil)
        end
        let(:provider) do
          instance_double(
            Email::Provider::Unknown,
            host: nil,
            sets_seen_flags_on_fetch?: false
          )
        end

        before do
          allow(input).to receive(:gets).and_return("add\n", "exit\n")
          allow(config.accounts).to receive(:<<)
          allow(Setup::Asker).to receive(:email).
            with(no_args) { added_email }
          allow(Setup::Account).to receive(:new).
            with(config, anything, anything) { setup_account }
          allow(Account).to receive(:new) { new_account }
          allow(Email::Provider).to receive(:for_address) { provider }

          subject.run
        end

        it "adds the account to the configuration" do
          expect(config.accounts).to have_received(:<<).with(new_account)
        end

        it "sets username" do
          expect(Account).to have_received(:new).with(hash_including(username: added_email))
        end

        it "sets blank password" do
          expect(Account).to have_received(:new).with(hash_including(password: ""))
        end

        it "sets local path" do
          expect(Account).to have_received(:new).with(hash_including(local_path: nil))
        end

        it "sets folders" do
          expect(Account).to have_received(:new).with(hash_including(folders: []))
        end

        context "when the account provider has a known host" do
          let(:provider) do
            instance_double(
              Email::Provider::Unknown,
              host: "imap.example.com",
              sets_seen_flags_on_fetch?: false
            )
          end

          it "sets the server" do
            expect(new_account).to have_received(:server=).with("imap.example.com")
          end
        end

        context "when the account provider sets Seen flags on fetch" do
          let(:provider) do
            instance_double(
              Email::Provider::Unknown,
              host: nil,
              sets_seen_flags_on_fetch?: true
            )
          end

          it "sets the relevant flag" do
            expect(new_account).to have_received(:reset_seen_flags_after_fetch=).with(true)
          end
        end
      end

      context "when 'save' is selected" do
        let(:config_modified) { true }

        before do
          allow(input).to receive(:gets) { "save\n" }
        end

        it "exits" do
          # N.B. this will hang forever if save does not cause an exit
          expect { subject.run }.to_not raise_error
        end

        it "saves the configuration" do
          expect(config).to receive(:save)

          subject.run
        end
      end

      context "when 'exit without saving' is selected" do
        let(:config_modified) { true }

        before do
          allow(input).to receive(:gets) { "exit\n" }
        end

        it "exits" do
          # N.B. this will hang forever if quit does not cause an exit
          expect { subject.run }.to_not raise_error
        end

        it "doesn't save the configuration" do
          expect(config).to_not receive(:save)

          subject.run
        end
      end
    end
  end
end
