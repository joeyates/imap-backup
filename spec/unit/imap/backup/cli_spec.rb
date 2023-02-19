module Imap::Backup
  require "support/shared_examples/an_action_that_handle_logger_options"

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

      it_behaves_like "an action that handles Logger options" do
        let(:action) do
          -> (options) do
            subject.invoke(:backup, [], options)
          end
        end
        let(:klass) { CLI::Backup }
        let(:expected_args) { [{}] }
      end
    end

    describe "#migrate" do
      let(:migrate) { instance_double(CLI::Migrate, run: nil) }

      before do
        allow(CLI::Migrate).to receive(:new) { migrate }
      end

      it "runs migrate" do
        subject.invoke(:migrate, ["source", "destination"])

        expect(migrate).to have_received(:run)
      end

      it_behaves_like "an action that handles Logger options" do
        let(:action) do
          -> (options) do
            subject.invoke(:migrate, ["source", "destination"], options)
          end
        end
        let(:klass) { CLI::Migrate }
        let(:expected_args) { ["source", "destination"] }
      end
    end

    describe "#mirror" do
      let(:mirror) { instance_double(CLI::Mirror, run: nil) }

      before do
        allow(CLI::Mirror).to receive(:new) { mirror }
      end

      it "runs mirror" do
        subject.invoke(:mirror, ["source", "destination"])

        expect(mirror).to have_received(:run)
      end

      it_behaves_like "an action that handles Logger options" do
        let(:action) do
          -> (options) do
            subject.invoke(:mirror, ["source", "destination"], options)
          end
        end
        let(:klass) { CLI::Mirror }
        let(:expected_args) { ["source", "destination"] }
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

      it_behaves_like "an action that handles Logger options" do
        let(:action) do
          -> (options) do
            subject.invoke(:restore, ["me@example.com"], options)
          end
        end
        let(:klass) { CLI::Restore }
        let(:expected_args) { ["me@example.com", {}] }
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

      it_behaves_like "an action that handles Logger options" do
        let(:action) do
          -> (options) do
            subject.invoke(:setup, [], options)
          end
        end
        let(:klass) { CLI::Setup }
        let(:expected_args) { [{}] }
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

      it_behaves_like "an action that handles Logger options" do
        let(:action) do
          -> (options) do
            subject.invoke(:stats, ["me@example.com"], options)
          end
        end
        let(:klass) { CLI::Stats }
        let(:expected_args) { ["me@example.com", {}] }
      end
    end
  end
end
