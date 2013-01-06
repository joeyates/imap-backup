# encoding: utf-8

require 'spec_helper'

describe Email::Mbox::Message do
  let(:from) { 'me@example.com' }
  let(:message_body) { "Foo\nBar\nFrom at the beginning of the line" }
  subject { Email::Mbox::Message.new(message_body) }

  context '#to_mbox' do
    let(:mail) { stub('Mail') }

    before do
      Mail.stub(:new).with(message_body).and_return(mail)
      mail.stub_chain(:envelope, :from).and_return(from)
    end

    it 'parses the message' do
      Mail.should_receive(:new).with(message_body).and_return(mail)

      subject.to_mbox
    end

    it "adds a 'From ' line at the start" do
      expect(subject.to_mbox).to start_with('From ' + from + "\n")
    end

    it "replaces existing 'From ' with '>From '" do
      expect(subject.to_mbox).to include("\n>From at the beginning")
    end
  end
end

