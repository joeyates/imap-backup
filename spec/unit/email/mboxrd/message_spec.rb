# encoding: utf-8

require 'spec_helper'

describe Email::Mboxrd::Message do
  let(:from) { 'me@example.com' }
  let(:date) { DateTime.new(2012, 12, 13, 18, 23, 45) }
  let(:message_body) do
    double('Body', :clone => cloned_message_body, :force_encoding => nil)
  end
  let(:cloned_message_body) { "Foo\nBar\nFrom at the beginning of the line\n>>From quoted" }

  subject { described_class.new(message_body) }

  context '#to_s' do
    let(:mail) { double('Mail', :from =>[from], :date => date) }

    before do
      allow(Mail).to receive(:new).with(cloned_message_body).and_return(mail)
    end

    it 'does not modify the message' do
      subject.to_s

      expect(message_body).to_not have_received(:force_encoding).with('binary')
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
