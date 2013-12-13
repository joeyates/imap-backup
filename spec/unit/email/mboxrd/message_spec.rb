# encoding: utf-8

require 'spec_helper'

describe Email::Mboxrd::Message do
  let(:from) { 'me@example.com' }
  let(:date) { DateTime.new(2012, 12, 13, 18, 23, 45) }
  let(:message_body) { "Foo\nBar\nFrom at the beginning of the line\n>>From quoted" }
  subject { Email::Mboxrd::Message.new(message_body) }

  context '#to_s' do
    let(:mail) do
      mail = stub('Mail')
      mail.stub(:from).and_return([from])
      mail.stub(:date).and_return(date)
      mail
    end

    before do
      Mail.stub(:new).with(message_body).and_return(mail)
    end

    it 'does not modify the message' do
      message_body2 = message_body.clone

      message_body.should_receive(:clone).and_return(message_body2)
      message_body.should_not_receive(:force_encoding).with('binary')

      subject.to_s
    end

    it 'parses the message' do
      Mail.should_receive(:new).with(message_body).and_return(mail)

      subject.to_s
    end

    it "adds a 'From ' line at the start" do
      expect(subject.to_s).to start_with('From ' + from + ' ' + date.asctime + "\n")
    end

    it "replaces existing 'From ' with '>From '" do
      expect(subject.to_s).to include("\n>From at the beginning")
    end

    it "appends > before '>+From '" do
      expect(subject.to_s).to include("\n>>>From quoted")
    end
  end
end
