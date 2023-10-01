require "imap/backup/setup/account"
require "imap/backup/setup/asker"
require "imap/backup/setup/connection_tester"
require "imap/backup/setup/folder_chooser"

module Imap::Backup
  RSpec.describe Setup::Account do
    subject { described_class.new(config, account, highline) }

    let(:account) do
      instance_double(
        Account,
        username: "user@example.com",
        password: existing_password,
        mirror_mode: mirror_mode,
        local_path: local_path,
        connection_options: connection_options,
        folder_blacklist: false,
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
    end
    let(:account1) { instance_double(Account) }
    let(:accounts) { [account, account1] }
    let(:existing_password) { "password" }
    let(:mirror_mode) { nil }
    let(:local_path) { "some/path" }
    let(:reset_seen_flags_after_fetch) { nil }
    let(:multi_fetch_size) { 1 }
    let(:connection_options) { nil }
    let(:highline) { instance_double(HighLine) }
    let(:config) { instance_double(Configuration, accounts: accounts, path: "config/path") }

    describe "#initialize" do
      [:config, :account, :highline].each do |param|
        it "expects #{param}" do
          expect(subject.send(param)).to eq(send(param))
        end
      end
    end

    describe "#run" do
      let(:highline_menu_class) do
        Class.new do
          attr_reader :choices

          def initialize
            @choices = {}
          end

          def choice(name, &block)
            choices[name] = block
          end

          def hidden(name, &block)
            choices[name] = block
          end
        end
      end

      let(:menu) { highline_menu_class.new }
      let(:header) { instance_double(Setup::Account::Header, run: nil) }

      before do
        allow(Kernel).to receive(:system)
        allow(Setup::Account::Header).to receive(:new) { header }
        allow(highline).to receive(:choose) do |&block|
          block.call(menu)
          throw :done
        end
      end

      describe "preparation" do
        it "clears the screen" do
          expect(Kernel).to receive(:system).with("clear")

          subject.run
        end

        it "shows the header" do
          expect(header).to receive(:run)

          subject.run
        end

        context "when #local_path is not set" do
          let(:local_path) { nil }

          before do
            allow(account).to receive(:"local_path=")
            subject.run
          end

          it "sets a default value" do
            expect(account).to have_received(:"local_path=").with("config/path/user_example.com")
          end
        end

        describe "menu" do
          it "shows the menu" do
            expect(highline).to receive(:choose)

            subject.run
          end
        end
      end

      describe "menu" do
        [
          "modify email",
          "modify password",
          "modify backup path",
          "choose folders to include in backups",
          "modify multi-fetch size (number of emails to fetch at a time)",
          "modify server",
          "modify connection options",
          "fix changes to unread flags during download",
          "test connection",
          "delete",
          "(q) return to main menu",
          "quit" # TODO: quit is hidden
        ].each do |item|
          before { subject.run }

          it "has a '#{item}' item" do
            expect(menu.choices).to include(item)
          end
        end
      end

      describe "choosing 'modify email'" do
        let(:email) { instance_double(Setup::Email, run: nil) }

        before do
          allow(Setup::Email).
            to receive(:new) { email }
          subject.run
          menu.choices["modify email"].call
        end

        it "runs Setup::Email" do
          expect(email).to have_received(:run)
        end
      end

      describe "choosing 'modify password'" do
        let(:new_password) { "new_password" }

        before do
          allow(account).to receive(:"password=")
          allow(Setup::Asker).
            to receive(:password) { new_password }
          subject.run
          menu.choices["modify password"].call
        end

        context "when the user enters a password" do
          it "updates the password" do
            expect(account).to have_received(:"password=").with(new_password)
          end
        end

        context "when the user cancels" do
          let(:new_password) { nil }

          it "does nothing" do
            expect(account.password).to eq(existing_password)
          end
        end
      end

      describe "choosing 'modify backup path'" do
        let(:backup_path) { instance_double(Setup::BackupPath, run: nil) }

        before do
          allow(Setup::BackupPath).to receive(:new) { backup_path }
          subject.run
          menu.choices["modify backup path"].call
        end

        it "runs Setup::BackupPath" do
          expect(backup_path).to have_received(:run)
        end
      end

      describe "choosing 'choose folders to include in backups'" do
        let(:chooser) do
          instance_double(Setup::FolderChooser, run: nil)
        end

        before do
          allow(Setup::FolderChooser).
            to receive(:new) { chooser }
          subject.run
          menu.choices["choose folders to include in backups"].call
        end

        it "edits folders" do
          expect(chooser).to have_received(:run)
        end
      end

      describe "choosing 'modify multi-fetch size'" do
        let(:supplied) { "10" }

        before do
          allow(account).to receive(:multi_fetch_size=)
          allow(highline).to receive(:ask).with("size: ") { supplied }

          subject.run
          menu.choices[
            "modify multi-fetch size (number of emails to fetch at a time)"
          ].call
        end

        it "sets the multi-fetch size" do
          expect(account).to have_received(:multi_fetch_size=).with(10)
        end

        context "when the supplied value is not a number" do
          let(:supplied) { "wrong!" }

          it "does nothing" do
            expect(account).to_not have_received(:multi_fetch_size=)
          end
        end

        context "when the supplied value is not a positive number" do
          let(:supplied) { "0" }

          it "does nothing" do
            expect(account).to_not have_received(:multi_fetch_size=)
          end
        end
      end

      describe "choosing 'modify server'" do
        let(:server) { "server" }

        before do
          allow(account).to receive(:"server=")
          allow(highline).to receive(:ask).with("server: ") { server }

          subject.run

          menu.choices["modify server"].call
        end

        it "updates the server" do
          expect(account).to have_received(:"server=").with(server)
        end
      end

      describe "choosing 'modify connection options'" do
        context "when the JSON is well formed" do
          let(:json) { "{}" }

          before do
            allow(highline).to receive(:ask).with("connections options (as JSON): ") { json }
            allow(account).to receive(:"connection_options=")

            subject.run

            menu.choices["modify connection options"].call
          end

          it "updates the connection options" do
            expect(account).to have_received(:"connection_options=").with(json)
          end
        end

        context "when an empty string is entered" do
          before do
            allow(highline).to receive(:ask).with("connections options (as JSON): ") { "" }
            allow(account).to receive(:"connection_options=")

            subject.run

            menu.choices["modify connection options"].call
          end

          it "unsets connection_options" do
            expect(account).to have_received(:"connection_options=").with("")
          end
        end

        context "when the JSON is malformed" do
          before do
            allow(Kernel).to receive(:puts)
            allow(highline).to receive(:ask).with("connections options (as JSON): ") { "xx" }
            allow(account).to receive(:"connection_options=").and_raise(JSON::ParserError)
            allow(highline).to receive(:ask).with("Press a key ")

            subject.run

            menu.choices["modify connection options"].call
          end

          it "does not fail" do
            expect { subject.run }.to_not raise_error
          end

          it "reports the problem" do
            expect(Kernel).to have_received(:puts).
              with(/Malformed/)
          end
        end
      end

      describe "toggling mirror_mode" do
        before { allow(account).to receive(:mirror_mode=) }

        context "when mirror_mode is not set" do
          before do
            subject.run
            menu.choices["toggle mode (keep/mirror)"].call
          end

          it "sets the flag" do
            expect(account).to have_received(:mirror_mode=).with(true)
          end
        end

        context "when mirror_mode is set" do
          let(:mirror_mode) { true }

          before do
            subject.run
            menu.choices["toggle mode (keep/mirror)"].call
          end

          it "sets the flag" do
            expect(account).to have_received(:mirror_mode=).with(nil)
          end
        end
      end

      describe "toggling 'fix changes...'" do
        context "when reset_seen_flags_after_fetch is not set" do
          before do
            allow(account).to receive(:reset_seen_flags_after_fetch=)

            subject.run
            menu.choices["fix changes to unread flags during download"].call
          end

          it "sets the flag" do
            expect(account).to have_received(:reset_seen_flags_after_fetch=).with(true)
          end
        end

        context "when reset_seen_flags_after_fetch is set" do
          let(:reset_seen_flags_after_fetch) { true }

          before do
            allow(account).to receive(:reset_seen_flags_after_fetch=)

            subject.run
            menu.choices["don't fix changes to unread flags during download"].call
          end

          it "unsets the flag" do
            expect(account).to have_received(:reset_seen_flags_after_fetch=).with(nil)
          end
        end
      end

      describe "choosing 'test connection'" do
        let(:connection_tester) do
          instance_double(
            Setup::ConnectionTester,
            test: "All fine"
          )
        end

        before do
          allow(Setup::ConnectionTester).
            to receive(:new) { connection_tester }
          allow(highline).to receive(:ask)
          subject.run
          menu.choices["test connection"].call
        end

        it "tests the connection" do
          expect(connection_tester).to have_received(:test)
        end
      end

      describe "choosing 'delete'" do
        let(:confirmed) { true }

        before do
          allow(account).to receive(:mark_for_deletion)
          allow(highline).to receive(:agree) { confirmed }
          subject.run
          catch :done do
            menu.choices["delete"].call
          end
        end

        it "asks for confirmation" do
          expect(highline).to have_received(:agree)
        end

        context "when the user confirms deletion" do
          it "flags the account to be deleted" do
            expect(account).to have_received(:mark_for_deletion)
          end
        end

        context "without confirmation" do
          let(:confirmed) { false }

          it "doesn't flag the account to be deleted" do
            expect(account).to_not have_received(:mark_for_deletion)
          end
        end
      end
    end
  end
end
