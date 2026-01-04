require "imap/backup/serializer/imap"

module Imap::Backup
  RSpec.describe Serializer::Imap do
    subject { described_class.new(folder_path) }

    let(:folder_path) { "folder_path" }
    let(:pathname) { "folder_path.imap" }
    let(:exists) { true }
    let(:existing) do
      {
        version: version,
        uid_validity: 99,
        messages: [{uid: 42, offset: 0, length: 12_345, flags: [:AFlag]}]
      }
    end
    let(:version) { 3 }
    let(:file) { instance_double(File, write: nil) }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(pathname) { exists }
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(pathname, "w").and_yield(file)
      allow(File).to receive(:read).with(pathname) { existing.to_json }
      allow(FileUtils).to receive(:rm).and_call_original
      allow(FileUtils).to receive(:rm).with(pathname)
    end

    describe "loading the metadata file" do
      context "when it is malformed" do
        before do
          allow(File).to receive(:read).with(pathname).and_raise(JSON::ParserError)
        end

        it "ignores the file" do
          subject.uid_validity

          expect(subject.messages).to eq([])
        end
      end

      context "when the 'messages' key is missing" do
        let(:existing) { {version: version, uid_validity: 99} }

        it "ignores the file" do
          expect(subject.messages).to eq([])
        end
      end

      context "when 'messages' is not an array" do
        let(:existing) { {version: version, uid_validity: 99, messages: "oops"} }

        it "ignores the file" do
          expect(subject.messages).to eq([])
        end
      end

      context "when the 'version' key is missing" do
        let(:existing) { {uid_validity: 99, messages: []} }

        it "ignores the file" do
          expect(subject.messages).to eq([])
        end
      end
    end

    describe "#transaction" do
      let(:logger) { instance_double(::Logger, error: nil, info: nil) }

      before do
        allow(Imap::Backup::Logger).to receive(:logger) { logger }
      end

      context "when the block completes" do
        it "persists any changes after the block" do
          subject.transaction do
            subject.update(42, length: 77_777)
          end

          expect(file).to have_received(:write).
            with(/"length":77777/)
        end
      end

      context "when the block raises an error" do
        let(:action) do
          proc do
            subject.transaction do
              subject.append(123, 321, flags: [:Flagged])
              raise "Boom"
            end
          end
        end

        it "re-raises the error" do
          expect { action.call }.to raise_error(RuntimeError, /Boom/)
        end

        it "rolls back the changes" do
          expect(subject).to receive(:rollback).and_call_original

          expect { action.call }.to raise_error(RuntimeError)
        end

        it "logs the failure" do
          expect { action.call }.to raise_error(RuntimeError)

          expect(logger).to have_received(:error).
            with("Imap::Backup::Serializer::Imap handling RuntimeError")
        end

        it "does not write to disk" do
          expect { action.call }.to raise_error(RuntimeError)

          expect(file).to_not have_received(:write)
        end
      end

      context "when a nested transaction is attempted" do
        let(:nested_action) do
          proc do
            subject.transaction do
              subject.transaction {}
            end
          end
        end

        it "raises a helpful error" do
          expect { nested_action.call }.
            to raise_error(RuntimeError, /nested transactions are not supported/)
        end

        it "rolls back the outer transaction" do
          expect(subject).to receive(:rollback).and_call_original

          expect { nested_action.call }.to raise_error(RuntimeError)
        end

        it "logs the nested transaction failure" do
          expect { nested_action.call }.to raise_error(RuntimeError)

          expect(logger).to have_received(:error).
            with("Imap::Backup::Serializer::Imap handling RuntimeError")
        end
      end

      context "when the transaction is rolled back manually" do
        it "does not save" do
          subject.transaction do
            subject.rollback
          end

          expect(file).to_not have_received(:write)
        end
      end
    end

    describe "#valid?" do
      context "when the metadata file has the correct data" do
        it "is true" do
          expect(subject.valid?).to be true
        end
      end

      context "when the metadata file doesn't exist" do
        let(:exists) { false }

        it "is false" do
          expect(subject.valid?).to be false
        end
      end

      context "when the version is wrong" do
        let(:version) { 1 }

        it "is false" do
          expect(subject.valid?).to be false
        end
      end

      context "when the uid_validity is missing" do
        let(:existing) { {version: version, uids: [42]} }

        it "is false" do
          expect(subject.valid?).to be false
        end
      end
    end

    describe "#append" do
      context "when the metadata file exists" do
        before { subject.append(123, 300, flags: [:MyFlag]) }

        it "loads the existing metadata" do
          existing = subject.get(42)

          expect(existing).to be_a(Serializer::Message)
        end

        it "appends the UID" do
          added = subject.get(123)

          expect(added.uid).to eq(123)
        end

        it "saves the file" do
          expect(file).to have_received(:write).
            with(/"version":3/)
        end
      end

      context "when the metadata file isn't valid" do
        let(:exists) { false }

        context "when the uid_validity is set" do
          before do
            subject.uid_validity = 999

            subject.append(123, 300, flags: [:MyFlag])
          end

          it "appends the UID" do
            added = subject.get(123)

            expect(added.uid).to eq(123)
          end

          it "saves the file" do
            expect(file).to have_received(:write).twice.with(/"version":3/)
          end
        end

        context "when the uid_validity is not set" do
          it "fails" do
            expect do
              subject.append(123, 300)
            end.to raise_error(RuntimeError, /without a uid_validity/)
          end
        end
      end
    end

    describe "#get" do
      context "when the UID exists" do
        it "returns a Serializer::Message" do
          result = subject.get(42)

          expect(result).to be_a(Serializer::Message)
        end

        it "returns the correct message" do
          result = subject.get(42)

          expect(result.uid).to eq(42)
        end

        it "returns a duplicate of the stored message" do
          stored = subject.messages.first
          result = subject.get(42)

          expect(result).to_not be(stored)
        end
      end

      context "when the UID does not exist" do
        it "returns nil" do
          result = subject.get(99)

          expect(result).to be_nil
        end
      end
    end

    describe "#uids" do
      it "returns all message UIDs" do
        expect(subject.uids).to eq([42])
      end
    end

    describe "#update" do
      context "when updating the message length" do
        before { subject.update(42, length: 77_777) }

        it "updates the length" do
          updated = subject.get(42)

          expect(updated.length).to eq(77_777)
        end

        it "saves the file" do
          expect(file).to have_received(:write).
            with(/"length":77777/)
        end
      end

      context "when updating the message flags" do
        before { subject.update(42, flags: [:Seen, :Flagged]) }

        it "updates the flags" do
          updated = subject.get(42)

          expect(updated.flags).to eq([:Seen, :Flagged])
        end

        it "saves the file" do
          expect(file).to have_received(:write).
            with(/"flags":\["Seen","Flagged"\]/)
        end
      end

      context "when the UID is missing" do
        it "raises an error" do
          expect do
            subject.update(99, length: 10)
          end.to raise_error(RuntimeError, /UID 99 not found/)
        end

        context "when updating raises an error" do
          it "does not save the file" do
            expect do
              subject.update(99, flags: [:Flagged])
            end.to raise_error(RuntimeError)

            expect(file).to_not have_received(:write)
          end
        end
      end
    end

    describe "#delete" do
      context "when the file exists" do
        it "deletes the file" do
          subject.delete

          expect(FileUtils).to have_received(:rm)
        end
      end

      context "when the file does not exist" do
        let(:exists) { false }

        it "does nothing" do
          subject.delete

          expect(FileUtils).to_not have_received(:rm)
        end
      end
    end

    describe "#rename" do
      before do
        allow(File).to receive(:rename)

        subject.rename("new_path")
      end

      context "when the metadata file exists" do
        it "sets the folder_path" do
          expect(subject.folder_path).to eq("new_path")
        end

        it "renames the metadata file" do
          expect(File).to have_received(:rename).with(pathname, "new_path.imap")
        end
      end

      context "when the metadata file isn't valid" do
        let(:exists) { false }

        it "sets the folder_path" do
          expect(subject.folder_path).to eq("new_path")
        end

        it "doesn't try to rename the metadata file" do
          expect(File).to_not have_received(:rename)
        end
      end
    end

    describe "#uid_validity" do
      it "returns the uid_validity" do
        expect(subject.uid_validity).to eq(99)
      end
    end

    describe "#uid_validity=" do
      before { subject.uid_validity = 567 }

      it "updates the uid_validity" do
        expect(subject.uid_validity).to eq(567)
      end

      it "saves the file" do
        expect(file).to have_received(:write).
          with(/"uid_validity":567/)
      end

      context "when no metadata file exists" do
        let(:exists) { false }

        it "saves an empty list of messages" do
          expect(file).to have_received(:write).
            with(/"messages":\[\]/)
        end
      end
    end

    describe "#update_uid" do
      context "when renaming to a new UID" do
        before { subject.update_uid(42, 57) }

        it "sets the UID" do
          added = subject.get(57)

          expect(added).to be_a(Serializer::Message)
        end

        it "saves the file" do
          expect(file).to have_received(:write).
            with(/\{"uid":57,"offset":0,"length":12345,"flags":\["AFlag"\]\}/)
        end
      end

      context "when the UID is not present" do
        let(:existing) { {uid_validity: 99, messages: [{length: 10, offset: 0, uid: 33}]} }

        it "doesn't save the file" do
          subject.update_uid(42, 57)

          expect(file).to_not have_received(:write)
        end
      end

      context "when the new UID already exists" do
        let(:existing) do
          {
            version: version,
            uid_validity: 99,
            messages: [
              {uid: 42, offset: 0, length: 12_345, flags: [:AFlag]},
              {uid: 77, offset: 12_345, length: 222, flags: [:Seen]}
            ]
          }
        end

        it "raises an error" do
          expect do
            subject.update_uid(42, 77)
          end.to raise_error(RuntimeError, /UID 77 already exists/)
        end

        it "does not save the file" do
          expect { subject.update_uid(42, 77) }.
            to raise_error(RuntimeError)

          expect(file).to_not have_received(:write)
        end
      end
    end
  end
end
