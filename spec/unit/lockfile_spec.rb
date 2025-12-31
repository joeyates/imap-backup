require "imap/backup/lockfile"

module Imap::Backup
  RSpec.describe Lockfile do
    subject { described_class.new(path: lockfile_path) }

    let(:lockfile_path) { "test.lock" }
    # We don't mock Process.pid because we want to use the real value in Process.kill
    let(:pid) { Process.pid }
    let(:proc_info) { instance_double(Struct::ProcTableStruct, starttime: starttime) }
    let(:starttime) { 456 }

    before do
      allow(Sys::ProcTable).to receive(:ps).with(pid: pid) { proc_info }
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(lockfile_path) { false }
      allow(File).to receive(:write).and_call_original
      allow(File).to receive(:write).with(lockfile_path, anything)
      allow(FileUtils).to receive(:rm_f).and_call_original
      allow(FileUtils).to receive(:rm_f).with(lockfile_path)
    end

    describe "#with_lock" do
      context "when proc_info is nil" do
        before do
          allow(Sys::ProcTable).to receive(:ps).with(pid: pid) { nil }
        end

        it "raises an error" do
          expect do
            subject.with_lock {}
          end.to raise_error("Unable to get process info for PID #{pid}")
        end
      end

      context "when the lockfile already exists" do
        before do
          allow(File).to receive(:exist?).with(lockfile_path) { true }
        end

        it "raises an error" do
          expect do
            subject.with_lock {}
          end.to raise_error("Lockfile already exists at #{lockfile_path}")
        end
      end

      it "creates the lockfile" do
        subject.with_lock {}

        expect(File).to have_received(:write).with(lockfile_path, anything)
      end

      it "saves the PID and stattime" do
        subject.with_lock {}

        data = JSON.generate({pid: pid, starttime: starttime})
        expect(File).to have_received(:write).with(lockfile_path, data)
      end

      it "removes the lockfile after the block" do
        subject.with_lock {}

        expect(FileUtils).to have_received(:rm_f).with(lockfile_path)
      end

      it "calls the block" do
        value = nil
        subject.with_lock { value = :called }

        expect(value).to eq(:called)
      end

      it "removes the lockfile even if an error occurs" do
        expect do
          subject.with_lock do
            raise "Boom"
          end
        end.to raise_error("Boom")

        expect(FileUtils).to have_received(:rm_f).with(lockfile_path)
      end

      it "removes the lockfile if the process is killed" do
        begin
          subject.with_lock do
            Process.kill("HUP", pid)
          end
        rescue SignalException
          # swallow exception
        end

        expect(FileUtils).to have_received(:rm_f).with(lockfile_path)
      end
    end

    describe "#exists?" do
      it "returns true if the lockfile exists" do
        allow(File).to receive(:exist?).with(lockfile_path) { true }

        expect(subject.exists?).to be true
      end

      it "returns false if the lockfile does not exist" do
        expect(subject.exists?).to be false
      end
    end

    describe "#remove" do
      it "removes the lockfile" do
        expect(FileUtils).to receive(:rm_f).with(lockfile_path)

        subject.remove
      end
    end

    describe "#stale?" do
      context "when the lockfile does not exist" do
        it "returns false" do
          expect(subject.stale?).to be false
        end
      end

      context "when the lockfile exists" do
        let(:file_content) { JSON.generate({pid: pid, starttime: starttime}) }

        before do
          allow(File).to receive(:exist?).with(lockfile_path) { true }
          allow(File).to receive(:read).with(lockfile_path) { file_content }
        end

        context "when the process does not exist" do
          before do
            allow(Sys::ProcTable).to receive(:ps).with(pid: pid) { nil }
          end

          it "returns true" do
            expect(subject.stale?).to be true
          end
        end

        context "when the PID exists with a different starttime" do
          let(:other_proc_info) { instance_double(Struct::ProcTableStruct, starttime: starttime + 1) }

          before do
            allow(Sys::ProcTable).to receive(:ps).with(pid: pid) { other_proc_info }
          end

          it "returns true" do
            expect(subject.stale?).to be true
          end
        end

        context "when the process exists with the same starttime" do
          before do
            allow(Sys::ProcTable).to receive(:ps).with(pid: pid) { proc_info }
          end

          it "returns false" do
            expect(subject.stale?).to be false
          end
        end
      end
    end
  end
end
