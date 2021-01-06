# rubocop:disable RSpec/NestedGroups

describe Imap::Backup::Configuration::Setup do
  include HighLineTestHelpers

  describe "#initialize" do
    context "without a config file" do
      it "works" do
        described_class.new
      end
    end
  end

  describe "#run" do
    subject { described_class.new }

    let(:normal) { {username: "account@example.com"} }
    let(:accounts) { [normal] }
    let(:store) do
      instance_double(
        Imap::Backup::Configuration::Store,
        "accounts": accounts,
        "path": "/base/path",
        "save": nil,
        "debug?": debug,
        "debug=": nil,
        "modified?": modified
      )
    end
    let(:debug) { false }
    let(:modified) { false }
    let!(:highline_streams) { prepare_highline }
    let(:input) { highline_streams[0] }
    let(:output) { highline_streams[1] }

    before do
      allow(Imap::Backup::Configuration::Store).to receive(:new) { store }
      allow(Imap::Backup).to receive(:setup_logging)
      allow(input).to receive(:eof?) { false }
      allow(input).to receive(:gets) { "exit\n" }
      allow(Kernel).to receive(:system)
    end

    describe "main menu" do
      before { subject.run }

      %w(add\ account save\ and\ exit exit\ without\ saving).each do |choice|
        it "includes #{choice}" do
          expect(output.string).to include(choice)
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
      let(:accounts) { [normal, modified, deleted] }
      let(:modified) { {username: "modified@example.com", modified: true} }
      let(:deleted) { {username: "deleted@example.com", delete: true} }

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

      before do
        allow(input).to receive(:gets).and_return("1\n", "exit\n")
        allow(Imap::Backup::Configuration::Asker).to receive(:email).
          with(no_args) { "new@example.com" }
        allow(Imap::Backup::Configuration::Account).to receive(:new).
          with(store, normal, anything) { account }
      end

      it "edits the account" do
        expect(account).to receive(:run)

        subject.run
      end
    end

    context "when adding accounts" do
      let(:blank_account) do
        {
          username: "new@example.com",
          password: "",
          local_path: "/base/path/new_example.com",
          folders: []
        }
      end
      let(:account) do
        instance_double(Imap::Backup::Configuration::Account, run: nil)
      end

      before do
        allow(input).to receive(:gets).and_return("add\n", "exit\n")
        allow(Imap::Backup::Configuration::Asker).to receive(:email).
          with(no_args) { "new@example.com" }
        allow(Imap::Backup::Configuration::Account).to receive(:new).
          with(store, blank_account, anything) { account }

        subject.run
      end

      it "adds account data" do
        expect(accounts[1]).to eq(blank_account)
      end

      context "when the account is a GMail account" do
        it "sets the server"
      end

      it "doesn't flag the unedited account as modified" do
        expect(accounts[1][:modified]).to be_nil
      end
    end

    describe "logging" do
      context "when debug logging is disabled" do
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
      before do
        allow(input).to receive(:gets) { "exit\n" }
      end

      it "exits" do
        # N.B. this will hang forever if quit does not cause an exit
        subject.run
      end

      context "when the configuration is modified" do
        let(:modified) { true }

        it "doesn't save the configuration" do
          expect(store).to_not receive(:save)

          subject.run
        end
      end

      context "when the configuration isn't modified" do
        it "doesn't save the configuration" do
          expect(store).to_not receive(:save)

          subject.run
        end
      end
    end
  end
end

# rubocop:enable RSpec/NestedGroups
