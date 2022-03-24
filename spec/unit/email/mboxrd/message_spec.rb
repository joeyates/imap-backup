msg_no_from = <<~NO_FROM
  Delivered-To: you@example.com
  From: example <www.example.com>
  To: FirstName LastName <you@example.com>
  Subject: Re: no subject
NO_FROM

msg_bad_from = <<~BAD_FROM
  Delivered-To: you@example.com
  from: "FirstName LastName (TEXT)" <"TEXT*" <no-reply@example.com>>
  To: FirstName LastName <you@example.com>
  Subject: Re: no subject
BAD_FROM

msg_no_from_but_return_path = <<~RETURN_PATH
  Delivered-To: you@example.com
  From: example <www.example.com>
  To: FirstName LastName <you@example.com>
  Return-Path: <me@example.com>
  Subject: Re: no subject
RETURN_PATH

msg_no_from_but_sender = <<~NOT_SENDER
  Delivered-To: you@example.com
  To: FirstName LastName <you@example.com>
  Subject: Re: no subject
  Sender: FistName LastName <me@example.com>
NOT_SENDER

describe Email::Mboxrd::Message do
  subject { described_class.new(message_body) }

  let(:from) { "me@example.com" }
  let(:date) { DateTime.new(2012, 12, 13, 18, 23, 45) }
  let(:message_body) do
    instance_double(String, clone: cloned_message_body, force_encoding: nil)
  end
  let(:cloned_message_body) do
    "Foo\nBar\nFrom at the beginning of the line\n>>From quoted"
  end
  let(:msg_good) do
    <<~GOOD
      Delivered-To: you@example.com
      From: Foo <foo@example.com>
      To: FirstName LastName <you@example.com>
      Date: #{date.rfc822}
      Subject: Re: no subject
    GOOD
  end

  let(:msg_bad_date) do
    <<~BAD
      Delivered-To: you@example.com
      From: Foo <foo@example.com>
      To: FirstName LastName <you@example.com>
      Date: Mon,5 May 2014 08:97:99 GMT
      Subject: Re: no subject
    BAD
  end

  describe ".from_serialized" do
    let(:serialized_message) { "From foo@a.com\n#{imap_message}" }
    let(:imap_message) { "Delivered-To: me@example.com\nFrom Me\n" }
    let!(:result) { described_class.from_serialized(serialized_message) }

    it "returns the message" do
      expect(result).to be_a(described_class)
    end

    it "removes one level of > before From" do
      expect(result.supplied_body).to eq(imap_message)
    end
  end

  describe "#to_serialized" do
    let(:mail) { instance_double(Mail::Message, from: [from], date: date) }

    before do
      allow(Mail).to receive(:new).with(cloned_message_body) { mail }
    end

    it "adds a 'From ' line at the start" do
      expected = "From #{from} #{date.asctime}\n"
      expect(subject.to_serialized).to start_with(expected)
    end

    it "replaces existing 'From ' with '>From '" do
      expect(subject.to_serialized).to include("\n>From at the beginning")
    end

    it "appends > before '>+From '" do
      expect(subject.to_serialized).to include("\n>>>From quoted")
    end

    context "when date is missing" do
      let(:date) { nil }

      it "does no fail" do
        expect { subject.to_serialized }.to_not raise_error
      end
    end
  end

  describe "From" do
    before do
      # call original for these tests because we want to test the behaviour of
      # class-under-test given different behaviour of the Mail parser
      allow(Mail).to receive(:new).and_call_original
    end

    context "when original message 'from' is missing" do
      let(:message_body) { msg_no_from }

      it "'from' is empty string" do
        expect(subject.to_serialized).to start_with("From \n")
      end
    end

    context "when original message 'from' is not a well-formed address" do
      let(:message_body) { msg_bad_from }

      it "'from' is empty string" do
        expect(subject.to_serialized).to start_with("From \n")
      end
    end

    context "when original message 'from' is nil and " \
            "'envelope from' is nil and 'return path' is available" do
      let(:message_body) { msg_no_from_but_return_path }

      it "'return path' is used as 'from'" do
        expect(subject.to_serialized).to start_with("From #{from}\n")
      end
    end

    context "with no from and a 'Sender'" do
      let(:message_body) { msg_no_from_but_sender }

      it "Sender is used as 'from'" do
        expect(subject.to_serialized).to start_with("From #{from}\n")
      end
    end
  end

  describe "#date" do
    let(:message_body) { msg_good }

    it "returns the date" do
      expect(subject.date).to eq(date)
    end

    context "with incorrect minutes and seconds" do
      let(:message_body) { msg_bad_date }

      it "returns nil" do
        expect(subject.date).to be_nil
      end
    end
  end

  describe "#imap_body" do
    let(:message_body) { "Ciao" }

    it "returns the supplied body" do
      expect(subject.imap_body).to eq(message_body)
    end

    context "when newlines are not IMAP standard" do
      let(:message_body) { "Ciao\nHello" }
      let(:corrected) { "Ciao\r\nHello" }

      it "corrects them" do
        expect(subject.imap_body).to eq(corrected)
      end
    end
  end
end
