require "spec_helper"

msg_no_from = %Q|Delivered-To: you@example.com
From: example <www.example.com>
To: FirstName LastName <you@example.com>
Subject: Re: no subject|

msg_bad_from = %Q|Delivered-To: you@example.com
from: "FirstName LastName (TEXT)" <"TEXT*" <no-reply@example.com>>
To: FirstName LastName <you@example.com>
Subject: Re: no subject
Sender: FistName LastName <"TEXT*"no-reply=example.com@example.com>|

msg_no_from_but_return_path = %Q|Delivered-To: you@example.com
From: example <www.example.com>
To: FirstName LastName <you@example.com>
Return-Path: <me@example.com>
Subject: Re: no subject|

describe Email::Mboxrd::Message do
  let(:from) { "me@example.com" }
  let(:date) { DateTime.new(2012, 12, 13, 18, 23, 45) }
  let(:message_body) do
    double("Body", clone: cloned_message_body, force_encoding: nil)
  end
  let(:cloned_message_body) { "Foo\nBar\nFrom at the beginning of the line\n>>From quoted" }

  subject { described_class.new(message_body) }

  context "#to_s" do
    let(:mail) { double("Mail", from: [from], date: date) }

    before do
      allow(Mail).to receive(:new).with(cloned_message_body).and_return(mail)
    end

    it "does not modify the message" do
      subject.to_s

      expect(message_body).to_not have_received(:force_encoding).with("binary")
    end

    it "adds a 'From ' line at the start" do
      expect(subject.to_s).to start_with("From " + from + " " + date.asctime + "\n")
    end

    it "replaces existing 'From ' with '>From '" do
      expect(subject.to_s).to include("\n>From at the beginning")
    end

    it "appends > before '>+From '" do
      expect(subject.to_s).to include("\n>>>From quoted")
    end

    context "when date is missing" do
      let(:date) { nil }

      it "does no fail" do
        expect { subject.to_s }.to_not raise_error
      end
    end
  end

  context '#from' do
    before do
      # call original for these tests because we want to test the behaviour of
      # class-under-test given different behaviour of the Mail parser
      allow(Mail).to receive(:new).and_call_original
    end

    context "when original message 'from' is nil" do
      let(:message_body) { msg_no_from }
      it "'from' is empty string" do
        expect(subject.to_s).to start_with("From  \n")
      end
    end

    context "when original message 'from' is a string but not an address" do
      let(:message_body) { msg_bad_from }
      it "'from' is empty string" do
        expect(subject.to_s).to start_with("From  \n")
      end
    end

    context "when original message 'from' is nil and 'envelope from' is nil and 'return path' is available" do
      let(:message_body) { msg_no_from_but_return_path }
      it "'return path' is used as 'from'" do
        expect(subject.to_s).to start_with("From " + from + " \n")
      end
    end
  end
end
