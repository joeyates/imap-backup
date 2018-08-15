require "spec_helper"

describe Imap::Backup::Configuration::FolderChooser do
  include HighLineTestHelpers

  context "#run" do
    let(:connection) do
      double("Imap::Backup::Account::Connection", folders: remote_folders)
    end
    let(:account) { {folders: []} }
    let(:remote_folders) { [] }

    subject { described_class.new(account) }

    before do
      allow(Imap::Backup::Account::Connection).
        to receive(:new).with(account) { connection }
      @input, @output = prepare_highline
      allow(subject).to receive(:system)
      allow(Imap::Backup.logger).to receive(:warn)
    end

    context "display" do
      before { subject.run }

      it "clears the screen" do
        expect(subject).to have_received(:system).with("clear")
      end

      it "should show the menu" do
        expect(@output.string).to match %r{Add/remove folders}
      end
    end

    context "folder listing" do
      let(:account) { {folders: [{name: "my_folder"}]} }
      let(:remote_folders) do
        # this one is already backed up:
        folder1 = double("folder", name: "my_folder")
        folder2 = double("folder", name: "another_folder")
        [folder1, folder2]
      end

      context "display" do
        before { subject.run }

        it "shows folders which are being backed up" do
          expect(@output.string).to include("+ my_folder")
        end

        it "shows folders which are not being backed up" do
          expect(@output.string).to include("- another_folder")
        end
      end

      context "adding folders" do
        before do
          allow(@input).to receive(:gets).and_return("2\n", "q\n")

          subject.run
        end

        specify "are added to the account" do
          expect(account[:folders]).to include({name: "another_folder"})
        end

        include_examples "it flags the account as modified"
      end

      context "removing folders" do
        before do
          allow(@input).to receive(:gets).and_return("1\n", "q\n")

          subject.run
        end

        specify "are removed from the account" do
          expect(account[:folders]).to_not include({name: "my_folder"})
        end

        include_examples "it flags the account as modified"
      end
    end

    context "when folders are not available" do
      let(:remote_folders) { nil }

      before do
        allow(Imap::Backup::Configuration::Setup.highline).
          to receive(:ask).and_return("q")
        subject.run
      end

      it "asks to press a key" do
        expect(Imap::Backup::Configuration::Setup.highline).
          to have_received(:ask).with("Press a key ")
      end
    end

    context "with connection errors" do
      before do
        allow(Imap::Backup::Account::Connection).
          to receive(:new).with(account).and_raise("error")
        allow(Imap::Backup::Configuration::Setup.highline).
          to receive(:ask).and_return("q")
        subject.run
      end

      it "prints an error message" do
        expect(Imap::Backup.logger).
          to have_received(:warn).with("Connection failed")
      end

      it "asks to continue" do
        expect(Imap::Backup::Configuration::Setup.highline).
          to have_received(:ask).with("Press a key ")
      end
    end
  end
end
