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
      allow(File).to receive(:unlink).and_call_original
      allow(File).to receive(:unlink).with(pathname)
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

    describe "#delete" do
      context "when the file exists" do
        it "deletes the file" do
          subject.delete

          expect(File).to have_received(:unlink)
        end
      end

      context "when the file does not exist" do
        let(:exists) { false }

        it "does nothing" do
          subject.delete

          expect(File).to_not have_received(:unlink)
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
      before { subject.update_uid(42, 57) }

      it "sets the UID" do
        added = subject.get(57)

        expect(added).to be_a(Serializer::Message)
      end

      it "saves the file" do
        expect(file).to have_received(:write).
          with(/\{"uid":57,"offset":0,"length":12345,"flags":\["AFlag"\]\}/)
      end

      context "when the UID is not present" do
        let(:existing) { {uid_validity: 99, messages: [{length: 10, offset: 0, uid: 33}]} }

        it "doesn't save the file" do
          expect(file).to_not have_received(:write)
        end
      end
    end
  end
end
