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

    describe "#single" do
      let(:backup) { instance_double(CLI::Single::Backup, run: nil) }

      before do
        allow(CLI::Single::Backup).to receive(:new) { backup }
      end

      describe "backup - short options" do
        it "accepts -e as a short option for --email" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-e", "foo@example.com"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(email: "foo@example.com"))
        end

        it "accepts -s as a short option for --server" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-s", "server"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(server: "server"))
        end

        it "accepts -p as a short option for --password" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-p", "MyS3kr1t"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(password: "MyS3kr1t"))
        end

        it "accepts -w as a short option for --password-environment-variable" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-w", "MY_PASSWORD"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(password_environment_variable: "MY_PASSWORD"))
        end

        it "accepts -W as a short option for --password-file" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-W", "some/file/with/password"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(password_file: "some/file/with/password"))
        end

        it "accepts -P as a short option for --path" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-P", "some/path"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(path: "some/path"))
        end

        it "accepts -F as a short option for --folder" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-F", "a-folder"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(folder: ["a-folder"]))
        end

        it "accepts -b as a short option for --folder-blacklist" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-b"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(folder_blacklist: true))
        end

        it "accepts -m as a short option for --mirror" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-m"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(mirror: true))
        end

        it "accepts -n as a short option for --multi-fetch-size" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-n", "99"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(multi_fetch_size: 99))
        end

        it "accepts -o as a short option for --connection-options" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-o", '{"foo": "bar"}'])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(connection_options: '{"foo": "bar"}'))
        end

        it "accepts -S as a short option for --download-strategy" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-S", "direct"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(download_strategy: "direct"))
        end

        it "accepts -R as a short option for --reset-seen-flags-after-fetch" do
          subject.invoke(Imap::Backup::CLI::Single, ["backup"], ["-R"])

          expect(CLI::Single::Backup).to have_received(:new).
            with(hash_including(reset_seen_flags_after_fetch: true))
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
