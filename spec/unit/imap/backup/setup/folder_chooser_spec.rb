module Imap::Backup
  RSpec.describe Setup::FolderChooser do
    include HighLineTestHelpers

    describe "#run" do
      subject { described_class.new(account) }

      let(:account) do
        instance_double(
          Account,
          client: client,
          folders: configured_folders,
          "folders=": nil
        )
      end
      let(:client) { instance_double(Client::Default, list: online_folders) }
      let(:configured_folders) { [] }
      let(:online_folders) { ["on_server"] }
      let!(:highline_streams) { prepare_highline }
      let(:input) { highline_streams[0] }
      let(:output) { highline_streams[1] }

      before do
        allow(Kernel).to receive(:system)
        allow(Logger.logger).to receive(:warn)
      end

      describe "display" do
        it "clears the screen" do
          expect(Kernel).to receive(:system).with("clear")

          subject.run
        end

        it "shows the menu" do
          subject.run

          expect(output.string).to match %r{Add/remove folders}
        end
      end

      describe "folder listing" do
        let(:configured_folders) { [{name: "my_folder"}] }
        let(:online_folders) do
          # N.B. my_folder is already backed up
          %w(my_folder another_folder)
        end

        describe "display" do
          before { subject.run }

          it "shows folders which are being backed up" do
            expect(output.string).to include("+ my_folder")
          end

          it "shows folders which are not being backed up" do
            expect(output.string).to include("- another_folder")
          end
        end

        context "when adding folders" do
          before do
            allow(input).to receive(:gets).and_return("2\n", "q\n")

            subject.run
          end

          specify "are added to the account" do
            expect(account).to have_received(:"folders=").
              with([{name: "my_folder"}, {name: "another_folder"}])
          end
        end

        context "when removing folders" do
          before do
            allow(input).to receive(:gets).and_return("1\n", "q\n")

            subject.run
          end

          specify "are removed from the account" do
            expect(account).to have_received(:"folders=").with([])
          end
        end
      end

      context "with missing remote folders" do
        let(:configured_folders) do
          [{name: "on_server"}, {name: "not_on_server"}]
        end

        before do
          allow(Kernel).to receive(:puts)
          subject.run
        end

        specify "are removed from the account" do
          expect(account).to have_received(:"folders=").
            with([{name: "on_server"}])
        end
      end

      context "when folders are not available" do
        let(:online_folders) { [] }

        before do
          allow(Setup.highline).
            to receive(:ask) { "q" }
        end

        it "asks to press a key" do
          expect(Setup.highline).
            to receive(:ask).with("Press a key ")

          subject.run
        end
      end

      context "with connection errors" do
        before do
          allow(account).to receive(:client).and_raise("error")
          allow(Setup.highline).
            to receive(:ask) { "q" }
        end

        it "prints an error message" do
          expect(Logger.logger).
            to receive(:warn).with("Connection failed")

          subject.run
        end

        it "asks to continue" do
          expect(Setup.highline).
            to receive(:ask).with("Press a key ")

          subject.run
        end
      end
    end
  end
end
