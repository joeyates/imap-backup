require "spec_helper"

describe Imap::Backup::Configuration::Setup do
  include HighLineTestHelpers

  context "#initialize" do
    context "without a config file" do
      it "works" do
        described_class.new
      end
    end
  end

  context "#run" do
    let(:normal) { {username: "account@example.com"} }
    let(:accounts) { [normal] }
    let(:store) do
      double(
        "Imap::Backup::Configuration::Store",
        :accounts => accounts,
        :path => "/base/path",
        :save => nil,
        :debug? => debug,
        :debug= => nil,
        :modified? => modified,
      )
    end
    let(:debug) { false }
    let(:modified) { false }

    before :each do
      allow(Imap::Backup::Configuration::Store).to receive(:new) { store }
      allow(Imap::Backup).to receive(:setup_logging)
      @input, @output = prepare_highline
      allow(@input).to receive(:eof?).and_return(false)
      allow(@input).to receive(:gets).and_return("exit\n")
      allow(subject).to receive(:system)
    end

    subject { described_class.new }

    context "main menu" do
      before { subject.run }

      %w(add\ account save\ and\ exit exit\ without\ saving).each do |choice|
        it "includes #{choice}" do
          expect(@output.string).to include(choice)
        end
      end
    end

    it "clears the screen" do
      subject.run

      expect(subject).to have_received(:system).with("clear")
    end

    it "updates logging status" do
      subject.run

      expect(Imap::Backup).to have_received(:setup_logging)
    end

    context "listing" do
      let(:accounts) { [normal, modified, deleted] }
      let(:modified) { {username: "modified@example.com", modified: true} }
      let(:deleted) { {username: "deleted@example.com", delete: true} }

      before { subject.run }

      context "normal accounts" do
        it "are listed" do
          expect(@output.string).to match /account@example.com/
        end
      end

      context "modified accounts" do
        it "are flagged" do
          expect(@output.string).to match /modified@example.com \*/
        end
      end

      context "deleted accounts" do
        it "are hidden" do
          expect(@output.string).to_not match /delete@example.com/
        end
      end
    end

    context "adding accounts" do
      let(:blank_account) do
        {
          username: "new@example.com",
          password: "",
          local_path: "/base/path/new_example.com",
          folders: []
        }
      end
      let(:account) { double("Imap::Backup::Configuration::Account", run: nil) }

      before do
        allow(@input).to receive(:gets).and_return("add\n", "exit\n")
        allow(Imap::Backup::Configuration::Asker).to receive(:email).
          with(no_args).and_return("new@example.com")
        allow(Imap::Backup::Configuration::Account).to receive(:new).
          with(store, blank_account, anything).and_return(account)

        subject.run
      end

      it "adds account data" do
        expect(accounts[1]).to eq(blank_account)
      end

      it "doesn't flag the unedited account as modified" do
        expect(accounts[1][:modified]).to be_nil
      end
    end

    context "logging" do
      context "when debug logging is disabled" do
        before do
          allow(@input).to receive(:gets).and_return("start\n", "exit\n")
          subject.run
        end

        it "shows a menu item" do
          expect(@output.string).to include("start logging")
        end

        context "when selected" do
          it "sets the debug flag" do
            expect(store).to have_received(:debug=).with(true)
          end

          it "updates logging status" do
            expect(Imap::Backup).to have_received(:setup_logging).twice
          end
        end
      end

      context "when debug logging is enabled" do
        let(:debug) { true }

        before do
          allow(@input).to receive(:gets).and_return("stop\n", "exit\n")
          subject.run
        end

        it "shows a menu item" do
          expect(@output.string).to include("stop logging")
        end

        context "when selected" do
          before do
            allow(@input).to receive(:gets).and_return("stop\n", "exit\n")
          end

          it "unsets the debug flag" do
            expect(store).to have_received(:debug=).with(false)
          end

          it "updates logging status" do
            expect(Imap::Backup).to have_received(:setup_logging).twice
          end
        end
      end
    end

    context "when 'save' is selected" do
      before do
        allow(@input).to receive(:gets).and_return("save\n")
        subject.run
      end

      it "exits" do
        # N.B. this will hang forever if save does not cause an exit
      end

      it "saves the configuration" do
        expect(store).to have_received(:save)
      end
    end

    context "when 'exit without saving' is selected" do
      before do
        allow(@input).to receive(:gets).and_return("exit\n")

        subject.run
      end

      it "exits" do
        # N.B. this will hang forever if quit does not cause an exit
      end

      context "when the configuration is modified" do
        let(:modified) { true }

        it "doesn't save the configuration" do
          expect(store).to_not have_received(:save)
        end
      end

      context "when the configuration isn't modified" do
        it "doesn't save the configuration" do
          expect(store).to_not have_received(:save)
        end
      end
    end
  end
end
