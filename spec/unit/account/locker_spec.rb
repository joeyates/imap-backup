require "imap/backup/account/locker"
require "imap/backup/account"
require "imap/backup/lockfile"
require "imap/backup/serializer/directory_maker"

module Imap
  module Backup
    RSpec.describe Account::Locker, :silence_logging do
      subject { described_class.new(account: account) }

      let(:lockfile_path) { "lockfile_path" }
      let(:account) do
        instance_double(Account, lockfile_path: lockfile_path, files_path: files_path)
      end
      let(:lockfile) { instance_double(Lockfile, exists?: false, remove: nil) }
      let(:directory_maker) { instance_double(Serializer::DirectoryMaker, run: nil) }
      let(:files_path) { instance_double(Serializer::Files::Path, base_path: "local_path", folder_name: nil) }

      before do
        allow(Lockfile).to receive(:new).with(path: lockfile_path) { lockfile }
        allow(Serializer::DirectoryMaker).to receive(:new).with(files_path: files_path) { directory_maker }
        allow(lockfile).to receive(:with_lock).and_yield
      end

      describe "#initialize" do
        it "sets the account" do
          expect(subject.account).to eq(account)
        end
      end

      describe "#with_lock" do
        it "creates a Lockfile" do
          expect(lockfile).to receive(:with_lock).and_yield

          subject.with_lock {}
        end

        it "calls the supplied the block" do
          yielded = false
          subject.with_lock { yielded = true }

          expect(yielded).to be true
        end

        context "when the lockfile does not exist" do
          it "ensures the account folders exist" do
            expect(directory_maker).to receive(:run)

            subject.with_lock {}
          end
        end

        context "when the lockfile exists and is stale" do
          before do
            allow(lockfile).to receive(:exists?) { true }
            allow(lockfile).to receive(:stale?) { true }
          end

          it "removes the lockfile" do
            expect(lockfile).to receive(:remove)

            subject.with_lock {}
          end

          it "logs the removal of the stale lockfile" do
            expect(Logger.logger).to receive(:info).with(
              "Stale lockfile '#{account.lockfile_path}' found. Removing it."
            )

            subject.with_lock {}
          end

          it "calls the supplied the block" do
            yielded = false
            subject.with_lock { yielded = true }

            expect(yielded).to be true
          end

          it "does not ensure the account folders exist" do
            expect(Serializer::DirectoryMaker).not_to receive(:new)

            subject.with_lock {}
          end
        end

        context "when the lockfile exists and is not stale" do
          before do
            allow(lockfile).to receive(:exists?) { true }
            allow(lockfile).to receive(:stale?) { false }
          end

          it "raises an error" do
            expect do
              subject.with_lock {}
            end.to raise_error("Lockfile '#{account.lockfile_path}' exists and is not stale.")
          end
        end

        context "when the process start time is unavailable" do
          it "calls the supplied block" do
            allow(lockfile).to receive(:with_lock).
              and_raise(Lockfile::ProcessStartTimeUnavailableError)

            yielded = false
            subject.with_lock { yielded = true }

            expect(yielded).to be true
          end
        end
      end
    end
  end
end
