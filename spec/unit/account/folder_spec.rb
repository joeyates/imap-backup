# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Account::Folder do
  include InputOutputTestHelpers

  let(:imap) { stub('Net::IMAP') }
  let(:connection) { stub('Imap::Backup::Account::Connection', :imap => imap) }
  let(:missing_mailbox_data) { stub('Data', :text => 'Unknown Mailbox: my_folder') }
  let(:missing_mailbox_response) { stub('Response', :data => missing_mailbox_data) }
  let(:missing_mailbox_error) { Net::IMAP::NoResponseError.new(missing_mailbox_response) }

  context 'with instance' do
    subject { Imap::Backup::Account::Folder.new(connection, 'my_folder') }

    context '#uids' do
      it 'lists available messages' do
        imap.should_receive(:examine).with('my_folder')
        imap.should_receive(:uid_search).with(['ALL']).and_return([5678, 123])

        subject.uids.should == [123, 5678]
      end

      it 'returns an empty array for missing mailboxes' do
        imap.
          should_receive(:examine).
          with('my_folder').
          and_raise(missing_mailbox_error)

        capturing_output do
          expect(subject.uids).to eq([])
        end
      end
    end

    context '#fetch' do
      let(:message_body) { 'the body' }
      let(:message) do
        {
          'RFC822' => message_body,
          'other'  => 'xxx'
        }
      end

      it 'requests the message, the flags and the date' do
        imap.should_receive(:examine).with('my_folder')
        imap.should_receive(:uid_fetch).
              with([123], ['RFC822', 'FLAGS', 'INTERNALDATE']).
              and_return([[nil, message]])

        subject.fetch(123)
      end

      it "returns nil if the mailbox doesn't exist" do
        imap.
          should_receive(:examine).
          with('my_folder').
          and_raise(missing_mailbox_error)

        capturing_output do
          expect(subject.fetch(123)).to be_nil
        end
      end

      if RUBY_VERSION > '1.9'
        it 'sets the encoding on the message' do
          imap.stub!(:examine => nil, :uid_fetch => [[nil, message]])

          message_body.should_receive(:force_encoding).with('utf-8')

          subject.fetch(123)
        end
      end
    end
  end
end

