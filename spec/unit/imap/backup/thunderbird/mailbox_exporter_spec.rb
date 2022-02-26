module Imap::Backup
  describe Thunderbird::MailboxExporter do
    subject { described_class.new("email", serializer, "profile", **args) }

    let(:args) { {} }
    let(:serializer) do
      instance_double(
        Serializer,
        folder: "folder",
        mbox_pathname: "mbox_pathname"
      )
    end
    let(:local_folder) do
      instance_double(
        Thunderbird::LocalFolder,
        exists?: local_folder_exists,
        full_path: "full_path",
        msf_exists?: msf_exists,
        msf_path: "msf_path",
        path: "path",
        set_up: set_up_result
      )
    end
    let(:local_folder_exists) { false }
    let(:msf_exists) { false }
    let(:set_up_result) { true }
    let(:file) { instance_double(File, write: nil) }
    let(:enumerator) { instance_double(Serializer::MboxEnumerator) }

    before do
      allow(File).to receive(:open).with("full_path", "w").and_yield(file)
      allow(File).to receive(:unlink)
      allow(Thunderbird::LocalFolder).to receive(:new) { local_folder }
      allow(Serializer::MboxEnumerator).to receive(:new) { enumerator }
      allow(enumerator).to receive(:each) { ["message"].enum_for(:each) }
      allow(Email::Mboxrd::Message).to receive(:clean_serialized) { "cleaned" }
      allow(Kernel).to receive(:puts)
    end

    describe "#run" do
      let!(:result) { subject.run }

      context "when the destination folder cannot be set up" do
        let(:set_up_result) { false }

        it "doesn't copy the mailbox" do
          expect(file).to_not have_received(:write)
        end

        it "returns false" do
          expect(result).to be false
        end
      end

      context "when the .msf file exists" do
        let(:msf_exists) { true }

        context "when 'force' is set" do
          let(:args) { {force: true} }

          it "deletes the file" do
            expect(File).to have_received(:unlink).with("msf_path")
          end
        end

        context "when 'force' isn't set" do
          it "doesn't copy the mailbox" do
            expect(file).to_not have_received(:write)
          end

          it "returns false" do
            expect(result).to be false
          end
        end
      end

      context "when the destination mailbox exists" do
        let(:local_folder_exists) { true }

        context "when 'force' is set" do
          let(:args) { {force: true} }

          it "writes the message" do
            expect(file).to have_received(:write)
          end

          it "returns true" do
            expect(result).to be true
          end
        end

        context "when 'force' isn't set" do
          it "doesn't copy the mailbox" do
            expect(file).to_not have_received(:write)
          end

          it "returns false" do
            expect(result).to be false
          end
        end
      end

      it "adds a 'From' line" do
        expect(file).to have_received(:write).with(/From - \w+ \w+ \d+ \d+:\d+:\d+/)
      end

      it "writes the cleaned message" do
        expect(file).to have_received(:write).with(/cleaned/)
      end

      it "returns true" do
        expect(result).to be true
      end
    end
  end
end
