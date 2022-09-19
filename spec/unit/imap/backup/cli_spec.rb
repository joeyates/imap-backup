module Imap::Backup
  RSpec.describe CLI do
    describe ".exit_on_failure?" do
      it "is true" do
        expect(described_class.exit_on_failure?).to be true
      end
    end

    describe "#backup" do
      let(:backup) { instance_double(CLI::Backup, run: nil) }

      before do
        allow(CLI::Backup).to receive(:new) { backup }

        subject.backup
      end

      it "runs Backup" do
        expect(backup).to have_received(:run)
      end
    end

    describe "#folders" do
      let(:folders) { instance_double(CLI::Folders, run: nil) }

      before do
        allow(CLI::Folders).to receive(:new) { folders }

        subject.folders
      end

      it "runs folders" do
        expect(folders).to have_received(:run)
      end
    end

    describe "#migrate" do
      let(:migrate) { instance_double(CLI::Migrate, run: nil) }

      before do
        allow(CLI::Migrate).to receive(:new) { migrate }

        subject.migrate("source", "destination")
      end

      it "runs migrate" do
        expect(migrate).to have_received(:run)
      end
    end

    describe "#restore" do
      let(:restore) { instance_double(CLI::Restore, run: nil) }

      before do
        allow(CLI::Restore).to receive(:new) { restore }

        subject.restore
      end

      it "runs restore" do
        expect(restore).to have_received(:run)
      end
    end

    describe "#setup" do
      let(:setup) { instance_double(CLI::Setup, run: nil) }

      before do
        allow(CLI::Setup).to receive(:new) { setup }

        subject.setup
      end

      it "runs setup" do
        expect(setup).to have_received(:run)
      end
    end
  end
end
