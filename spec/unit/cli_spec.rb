require "imap/backup/cli"

require "support/shared_examples/an_action_that_handles_logger_options"

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
      end

      it "runs Backup" do
        subject.backup

        expect(backup).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:backup, [], options)
        end
      ) do
        it "does not pass the option to the class" do
          expect(CLI::Backup).to have_received(:new).with({})
        end
      end
    end

    describe "#migrate" do
      let(:transfer) { instance_double(CLI::Transfer, run: nil) }

      before do
        allow(CLI::Transfer).to receive(:new) { transfer }
      end

      it "runs transfer" do
        subject.invoke(:migrate, %w[source destination])

        expect(transfer).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:migrate, %w[source destination], options)
        end
      ) do
        it "does not pass the option to the class" do
          expect(CLI::Transfer).to have_received(:new).with(:migrate, "source", "destination", {})
        end
      end
    end

    describe "#mirror" do
      let(:transfer) { instance_double(CLI::Transfer, run: nil) }

      before do
        allow(CLI::Transfer).to receive(:new) { transfer }
      end

      it "runs transfer" do
        subject.invoke(:mirror, %w[source destination])

        expect(transfer).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:mirror, %w[source destination], options)
        end
      ) do
        it "does not pass the option to the class" do
          expect(CLI::Transfer).to have_received(:new).with(:mirror, "source", "destination", {})
        end
      end
    end

    describe "#restore" do
      let(:restore) { instance_double(CLI::Restore, run: nil) }

      before do
        allow(CLI::Restore).to receive(:new) { restore }
      end

      it "runs restore" do
        subject.restore

        expect(restore).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:restore, ["me@example.com"], options)
        end
      ) do
        it "does not pass the option to the class" do
          expect(CLI::Restore).to have_received(:new).with("me@example.com", {})
        end
      end
    end

    describe "#setup" do
      let(:setup) { instance_double(CLI::Setup, run: nil) }

      before do
        allow(CLI::Setup).to receive(:new) { setup }
      end

      it "runs setup" do
        subject.setup

        expect(setup).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:setup, [], options)
        end
      ) do
        it "does not pass the option to the class" do
          expect(CLI::Setup).to have_received(:new).with({})
        end
      end
    end

    describe "#stats" do
      let(:stats) { instance_double(CLI::Stats, run: nil) }

      before do
        allow(CLI::Stats).to receive(:new) { stats }
      end

      it "runs stats" do
        subject.stats("me@example.com")

        expect(stats).to have_received(:run)
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:stats, ["me@example.com"], options)
        end
      ) do
        it "does not pass the option to the class" do
          expect(CLI::Stats).to have_received(:new).with("me@example.com", {})
        end
      end
    end
  end
end
