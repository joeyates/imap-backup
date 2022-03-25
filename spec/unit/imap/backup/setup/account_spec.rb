module Imap::Backup
  describe Setup::Account do
    subject { described_class.new(config, account, highline) }

    let(:account) do
      instance_double(
        Account,
        username: existing_email,
        password: existing_password,
        local_path: "/backup/path",
        folders: [{name: "my_folder"}],
        multi_fetch_size: multi_fetch_size,
        server: "imap.example.com",
        connection_options: connection_options,
        modified?: false
      )
    end
    let(:account1) { instance_double(Account) }
    let(:accounts) { [account, account1] }
    let(:existing_email) { "user@example.com" }
    let(:existing_password) { "password" }
    let(:other_email) { "other@example.com" }
    let(:multi_fetch_size) { 1 }
    let(:connection_options) { nil }
    let(:highline) { instance_double(HighLine) }
    let(:config) { instance_double(Configuration, accounts: accounts) }

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
          attr_accessor :header

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

      before do
        allow(Kernel).to receive(:system)
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
          "choose backup folders",
          "modify multi-fetch size (number of emails to fetch at a time)",
          "modify server",
          "modify connection options",
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

      describe "account details" do
        [
          ["email", /email\s+user@example.com/],
          ["password", /password\s+x+/],
          ["path", %r(path\s+/backup/path)],
          ["folders", /folders\s+my_folder/],
          ["server", /server\s+imap.example.com/]
        ].each do |attribute, value|
          before { subject.run }

          it "shows the #{attribute}" do
            expect(menu.header).to match(value)
          end
        end

        context "with no password" do
          let(:existing_password) { "" }

          before { subject.run }

          it "indicates that a password is not set" do
            expect(menu.header).to match(/^password\s+\(unset\)/)
          end
        end

        context "with multi_fetch_size" do
          let(:multi_fetch_size) { 4 }

          it "shows the size" do
            expect(menu.header).to match(/^multi-fetch\s+4/)
          end
        end

        context "with connection_options" do
          let(:connection_options) { {some: "option"} }

          it "shows the options" do
            expect(menu.header).to match(/^connection options\s+'{"some":"option"}'/)
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

      describe "choosing 'choose backup folders'" do
        let(:chooser) do
          instance_double(Setup::FolderChooser, run: nil)
        end

        before do
          allow(Setup::FolderChooser).
            to receive(:new) { chooser }
          subject.run
          menu.choices["choose backup folders"].call
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
            subject.run
          end

          it "reports the problem" do
            expect(Kernel).to have_received(:puts).
              with(/Malformed/)
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
