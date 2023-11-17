require "imap/backup/serializer/message"
require "imap/backup/email/mboxrd/message"
require "imap/backup/serializer/mbox"

module Imap::Backup
  RSpec.describe Serializer::Message do
    subject { described_class.new(**parameters) }

    let(:parameters) do
      {uid: uid, offset: offset, length: length, mbox: mbox, flags: flags}
    end
    let(:uid) { 42 }
    let(:offset) { 13 }
    let(:length) { 23 }
    let(:mbox) { instance_double(Serializer::Mbox) }
    let(:flags) { %w(foo bar) }
    let(:raw) { "raw message" }
    let(:message) { instance_double(Email::Mboxrd::Message) }
    let(:date) { Date.today }

    before do
      allow(Email::Mboxrd::Message).to receive(:from_serialized) { message }
      allow(mbox).to receive(:read).with(offset, length) { raw }
      allow(message).to receive(:supplied_body) { "supplied_body" }
      allow(message).to receive(:imap_body) { "imap_body" }
      allow(message).to receive(:date) { date }
      allow(message).to receive(:subject) { subject }
    end

    describe "#flags" do
      let(:parameters) do
        {uid: uid, offset: offset, length: length, mbox: mbox}
      end

      it "defaults to an empty Array" do
        expect(subject.flags).to eq([])
      end
    end

    describe "#to_h" do
      let(:result) { subject.to_h }

      it "returns the uid" do
        expect(result[:uid]).to eq(uid)
      end

      it "returns the offset" do
        expect(result[:offset]).to eq(offset)
      end

      it "returns the length" do
        expect(result[:length]).to eq(length)
      end

      it "returns the flags" do
        expect(result[:flags]).to eq(flags)
      end
    end

    describe "#message" do
      let(:result) { subject.message }

      it "returns the message from the mbox" do
        expect(result).to eq(message)
      end
    end

    describe "#body" do
      it "returns the message body" do
        expect(subject.body).to eq("supplied_body")
      end
    end

    describe "#imap_body" do
      it "returns the message body" do
        expect(subject.imap_body).to eq("imap_body")
      end
    end

    describe "#date" do
      it "returns the message date" do
        expect(subject.date).to eq(date)
      end
    end

    describe "#subject" do
      it "returns the message subject" do
        expect(subject.subject).to eq(subject)
      end
    end
  end
end
