describe Imap::Backup::Configuration::Account do
  ACCOUNT = "account".freeze
  GMAIL_IMAP_SERVER = "imap.gmail.com".freeze
  HIGHLINE = "highline".freeze
  STORE = "store".freeze

  subject { described_class.new(store, account, highline) }

  let(:account) { ACCOUNT }
  let(:highline) { HIGHLINE }
  let(:store) { STORE }

  describe "#initialize" do
    [:store, :account, :highline].each do |param|
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

    let(:highline) { instance_double(HighLine) }
    let(:menu) { highline_menu_class.new }
    let(:store) do
      instance_double(Imap::Backup::Configuration::Store, accounts: accounts)
    end
    let(:accounts) { [account, account1] }
    let(:account) do
      {
        username: existing_email,
        server: current_server,
        local_path: "/backup/path",
        folders: [{name: "my_folder"}],
        password: existing_password
      }
    end
    let(:account1) do
      {
        username: other_email,
        local_path: other_existing_path
      }
    end
    let(:existing_email) { "user@example.com" }
    let(:new_email) { "foo@example.com" }
    let(:current_server) { "imap.example.com" }
    let(:existing_password) { "password" }
    let(:other_email) { "other@example.com" }
    let(:other_existing_path) { "/other/existing/path" }

    before do
      allow(Kernel).to receive(:system)
      allow(Kernel).to receive(:puts)
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
        "modify server",
        "modify backup path",
        "choose backup folders",
        "test connection",
        "delete",
        "return to main menu",
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
        ["email", /email:\s+user@example.com/],
        ["server", /server:\s+imap.example.com/],
        ["password", /password:\s+x+/],
        ["path", %r(path:\s+/backup/path)],
        ["folders", /folders:\s+my_folder/]
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
          expect(menu.header).to include("password: (unset)")
        end
      end
    end

    describe "choosing 'modify email'" do
      before do
        allow(Imap::Backup::Configuration::Asker).
          to receive(:email) { new_email }
        subject.run
        menu.choices["modify email"].call
      end

      context "when the server is blank" do
        [
          ["GMail", "foo@gmail.com", GMAIL_IMAP_SERVER],
          ["Fastmail", "bar@fastmail.fm", "imap.fastmail.com"],
          ["Fastmail", "bar@fastmail.com", "imap.fastmail.com"]
        ].each do |service, email, expected|
          context service do
            let(:new_email) { email }

            context "with nil" do
              let(:current_server) { nil }

              it "sets a default server" do
                expect(account[:server]).to eq(expected)
              end
            end

            context "with an empty string" do
              let(:current_server) { "" }

              it "sets a default server" do
                expect(account[:server]).to eq(expected)
              end
            end
          end
        end

        context "when the domain is unrecognized" do
          let(:current_server) { nil }
          let(:provider) do
            instance_double(Email::Provider, provider: :default)
          end

          before do
            allow(Email::Provider).to receive(:for_address) { provider }
          end

          it "does not set a default server" do
            expect(account[:server]).to be_nil
          end
        end
      end

      context "when the email is new" do
        it "modifies the email address" do
          expect(account[:username]).to eq(new_email)
        end

        include_examples "it flags the account as modified"
      end

      context "when the email already exists" do
        let(:new_email) { other_email }

        it "indicates the error" do
          expect(Kernel).to have_received(:puts).
            with("There is already an account set up with that email address")
        end

        it "doesn't set the email" do
          expect(account[:username]).to eq(existing_email)
        end

        include_examples "it doesn't flag the account as modified"
      end
    end

    describe "choosing 'modify password'" do
      let(:new_password) { "new_password" }

      before do
        allow(Imap::Backup::Configuration::Asker).
          to receive(:password) { new_password }
        subject.run
        menu.choices["modify password"].call
      end

      context "when the user enters a password" do
        it "updates the password" do
          expect(account[:password]).to eq(new_password)
        end

        include_examples "it flags the account as modified"
      end

      context "when the user cancels" do
        let(:new_password) { nil }

        it "does nothing" do
          expect(account[:password]).to eq(existing_password)
        end

        include_examples "it doesn't flag the account as modified"
      end
    end

    describe "choosing 'modify password' when the server is for GMail" do
      let(:new_password) { "new_password" }
      let(:current_server) { GMAIL_IMAP_SERVER }
      let(:gmail_oauth2) do
        instance_double(Imap::Backup::Configuration::GmailOauth2, run: nil)
      end

      before do
        allow(Imap::Backup::Configuration::Asker).
          to receive(:password) { new_password }
        allow(Imap::Backup::Configuration::GmailOauth2).
          to receive(:new).
            with(account) { gmail_oauth2 }
      end

      context "when the environment IMAP_BACKUP_ENABLE_GMAIL_OAUTH2 is set" do
        before do
          ENV["IMAP_BACKUP_ENABLE_GMAIL_OAUTH2"] = "1"
          subject.run
          menu.choices["modify password"].call
        end

        after do
          ENV.delete("IMAP_BACKUP_ENABLE_GMAIL_OAUTH2")
        end

        it "sets up GMail OAuth2" do
          expect(gmail_oauth2).to have_received(:run)
        end
      end

      context "when the environment IMAP_BACKUP_ENABLE_GMAIL_OAUTH2 is not set" do
        before do
          subject.run
          menu.choices["modify password"].call
        end

        it "sets up GMail OAuth2" do
          expect(gmail_oauth2).to_not have_received(:run)
        end
      end
    end

    describe "choosing 'modify server'" do
      let(:server) { "server" }

      before do
        allow(highline).to receive(:ask).with("server: ") { server }

        subject.run

        menu.choices["modify server"].call
      end

      it "updates the server" do
        expect(account[:server]).to eq(server)
      end

      include_examples "it flags the account as modified"
    end

    describe "choosing 'modify backup path'" do
      let(:new_backup_path) { "/new/path" }

      before do
        @validator = nil
        allow(
          Imap::Backup::Configuration::Asker
        ).to receive(:backup_path) do |_path, validator|
          @validator = validator
          new_backup_path
        end
        subject.run
        menu.choices["modify backup path"].call
      end

      it "updates the path" do
        expect(account[:local_path]).to eq(new_backup_path)
      end

      context "when the path is not used by other backups" do
        it "is accepts it" do
          # rubocop:disable RSpec/InstanceVariable
          expect(@validator.call("/unknown/path")).to be_truthy
          # rubocop:enable RSpec/InstanceVariable
        end
      end

      context "when the path is used by other backups" do
        it "fails validation" do
          # rubocop:disable RSpec/InstanceVariable
          expect(@validator.call(other_existing_path)).to be_falsey
          # rubocop:enable RSpec/InstanceVariable
        end
      end

      include_examples "it flags the account as modified"
    end

    describe "choosing 'choose backup folders'" do
      let(:chooser) do
        instance_double(Imap::Backup::Configuration::FolderChooser, run: nil)
      end

      before do
        allow(Imap::Backup::Configuration::FolderChooser).
          to receive(:new) { chooser }
        subject.run
        menu.choices["choose backup folders"].call
      end

      it "edits folders" do
        expect(chooser).to have_received(:run)
      end
    end

    describe "choosing 'test connection'" do
      before do
        allow(Imap::Backup::Configuration::ConnectionTester).
          to receive(:test) { "All fine" }
        allow(highline).to receive(:ask)
        subject.run
        menu.choices["test connection"].call
      end

      it "tests the connection" do
        expect(Imap::Backup::Configuration::ConnectionTester).
          to have_received(:test).with(account)
      end
    end

    describe "choosing 'delete'" do
      let(:confirmed) { true }

      before do
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
        include_examples "it flags the account to be deleted"
      end

      context "without confirmation" do
        let(:confirmed) { false }

        include_examples "it doesn't flag the account to be deleted"
      end
    end
  end
end
