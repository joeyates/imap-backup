require "imap/backup/serializer/mbox_enumerator"

module Imap::Backup
  describe Serializer::MboxEnumerator do
    subject { described_class.new(mbox_pathname) }

    let(:mbox_pathname) { "/mbox/pathname" }
    let(:mbox_file) { instance_double(File) }
    let(:lines) { message1 + message2 + [nil] }
    let(:message1) do
      [
        "From Frida\r\n",
        "Hello\r\n"
      ]
    end
    let(:message2) do
      [
        "From John\r\n",
        "Hi\r\n"
      ]
    end

    before do
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(mbox_pathname, "rb").and_yield(mbox_file)
      allow(mbox_file).to receive(:gets).and_return(*lines)
    end

    describe "#each" do
      it "reads files as binary" do
        subject.each {}

        expect(File).to have_received(:open).with(mbox_pathname, "rb")
      end

      it "yields messages" do
        expect { |b| subject.each(&b) }.
          to yield_successive_args(message1.join, message2.join)
      end

      context "without a block" do
        it "returns an Enumerator" do
          expect(subject.each).to be_a(Enumerator)
        end
      end
    end

    describe "#map" do
      it "reads files as binary" do
        subject.map {}

        expect(File).to have_received(:open).with(mbox_pathname, "rb")
      end

      it "yields messages" do
        expect { |b| subject.map(&b) }.
          to yield_successive_args(message1.join, message2.join)
      end

      it "returns results of calling the supplied block" do
        expected = [message1.join.length, message2.join.length]

        expect(subject.map(&:length)).to eq(expected)
      end

      context "without a block" do
        it "returns an Enumerator" do
          expect(subject.map).to be_a(Enumerator)
        end
      end
    end
  end
end
