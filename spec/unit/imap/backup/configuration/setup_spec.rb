describe Imap::Backup::Configuration::Setup do
  include HighLineTestHelpers

  subject { described_class.new }

  let(:normal_account) do
    instance_double(
      Imap::Backup::Account,
      username: "account@example.com",
      marked_for_deletion?: false,
      modified?: false
    )
  end
  let(:modified_account) do
    instance_double(
      Imap::Backup::Account,
      username: "modified@example.com",
      marked_for_deletion?: false,
      modified?: true
    )
  end
  let(:deleted_account) do
    instance_double(
      Imap::Backup::Account,
      username: "delete@example.com",
      marked_for_deletion?: true,
      modified?: false
    )
  end
  let(:accounts) { [normal_account] }
  let(:store) do
    instance_double(
      Imap::Backup::Configuration::Store,
      "accounts": accounts,
      "path": "/base/path",
      "save": nil,
      "debug?": debug,
      "debug=": nil,
      "modified?": config_modified
    )
  end
  let(:debug) { false }
  let(:config_modified) { false }
  let!(:highline_streams) { prepare_highline }
  let(:input) { highline_streams[0] }
  let(:output) { highline_streams[1] }
  let(:gmail_imap_server) { "imap.gmail.com" }

  describe "#initialize" do
    context "without a config file" do
      it "works" do
        described_class.new
      end
    end
  end

  describe "#run" do
    before do
      allow(Imap::Backup::Configuration::Store).to receive(:new) { store }
      allow(Imap::Backup).to receive(:setup_logging)
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
    end

    it "clears the screen" do
      expect(Kernel).to receive(:system).with("clear")

      subject.run
    end

    it "updates logging status" do
      expect(Imap::Backup).to receive(:setup_logging)

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

    context "when editing accounts" do
      let(:account) do
        instance_double(Imap::Backup::Configuration::Account, run: nil)
      end
      let(:config_modified) { true }

      before do
        allow(input).to receive(:gets).and_return("1\n", "exit\n")
        allow(Imap::Backup::Configuration::Asker).to receive(:email).
          with(no_args) { "new@example.com" }
        allow(Imap::Backup::Configuration::Account).to receive(:new).
          with(store, normal_account, anything) { account }
      end

      it "edits the account" do
        expect(account).to receive(:run)

        subject.run
      end
    end

    context "when adding accounts" do
      let(:blank_account) do
        {
          username: added_email,
          password: "",
          local_path: local_path,
          folders: []
        }
      end
      let(:account) do
        instance_double(Imap::Backup::Configuration::Account, run: nil)
      end
      let(:config_modified) { true }
      let(:added_email) { "new@example.com" }
      let(:local_path) { "/base/path/new_example.com" }

      before do
        allow(input).to receive(:gets).and_return("add\n", "exit\n")
        allow(Imap::Backup::Configuration::Asker).to receive(:email).
          with(no_args) { added_email }
        allow(Imap::Backup::Configuration::Account).to receive(:new).
          with(store, anything, anything) { account }

        subject.run
      end

      it "sets username" do
        expect(accounts[1].username).to eq(added_email)
      end

      it "sets blank password" do
        expect(accounts[1].password).to eq("")
      end

      it "sets local_path" do
        expect(accounts[1].local_path).to eq(local_path)
      end

      it "sets folders" do
        expect(accounts[1].folders).to eq([])
      end

      context "when the account is a GMail account" do
        let(:added_email) { "new@gmail.com" }
        let(:local_path) { "/base/path/new_gmail.com" }

        it "sets the server" do
          expect(accounts[1].server).to eq(gmail_imap_server)
        end
      end

      it "doesn't flag the unedited account as modified" do
        expect(accounts[1].modified?).to be_falsey
      end
    end

    describe "logging" do
      context "when debug logging is disabled" do
        let(:config_modified) { true }

        before do
          allow(input).to receive(:gets).and_return("start\n", "exit\n")
        end

        it "shows a menu item" do
          subject.run

          expect(output.string).to include("start logging")
        end

        context "when selected" do
          it "sets the debug flag" do
            expect(store).to receive(:debug=).with(true)

            subject.run
          end

          it "updates logging status" do
            expect(Imap::Backup).to receive(:setup_logging).twice

            subject.run
          end
        end
      end

      context "when debug logging is enabled" do
        let(:debug) { true }
        let(:config_modified) { true }

        before do
          allow(input).to receive(:gets).and_return("stop\n", "exit\n")
        end

        it "shows a menu item" do
          subject.run

          expect(output.string).to include("stop logging")
        end

        context "when selected" do
          before do
            allow(input).to receive(:gets).and_return("stop\n", "exit\n")
          end

          it "unsets the debug flag" do
            expect(store).to receive(:debug=).with(false)

            subject.run
          end

          it "updates logging status" do
            expect(Imap::Backup).to receive(:setup_logging).twice

            subject.run
          end
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
        subject.run
      end

      it "saves the configuration" do
        expect(store).to receive(:save)

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
        subject.run
      end

      it "doesn't save the configuration" do
        expect(store).to_not receive(:save)

        subject.run
      end
    end
  end
end
