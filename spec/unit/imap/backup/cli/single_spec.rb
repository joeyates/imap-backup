require "imap/backup/cli/single"

module Imap::Backup
  RSpec.describe CLI::Single do
    describe "#backup" do
      let(:backup) { instance_double(CLI::Single::Backup, run: nil) }

      before do
        allow(CLI::Single::Backup).to receive(:new) { backup }
      end

      it "runs Direct" do
        subject.backup

        expect(backup).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          with_required = options.merge({"username" => "me", "server" => "host"})
          subject.invoke(:backup, [], with_required)
        end
      ) do
        it "passes other options to the class" do
          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including({username: "me", server: "host"}))
        end

        it "does not pass loggint options to the class" do
          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_not_including([:quiet, :verbose]))
        end
      end
    end
  end
end

