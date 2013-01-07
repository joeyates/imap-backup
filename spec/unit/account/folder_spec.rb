# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Account::Folder do

  context 'with instance' do

    before :each do
      @imap    = stub('Net::IMAP')
      @connection = stub('Imap::Backup::Account::Connection', :imap => @imap)
    end

    subject { Imap::Backup::Account::Folder.new(@connection, 'my_folder') }

    context '#uids' do

      it 'should list available messages' do
        @imap.should_receive(:examine).with('my_folder')
        @imap.should_receive(:uid_search).with(['ALL']).and_return([5678, 123])

        subject.uids.should == [123, 5678]
      end

    end

    context '#fetch' do
      before :each do
        @message_body = 'the body'
        @message = {
          'RFC822' => @message_body,
          'other'  => 'xxx'
        }
      end

      it 'should request the message, the flags and the date' do
        @imap.should_receive(:examine).with('my_folder')
        @imap.should_receive(:uid_fetch).
              with([123], ['RFC822', 'FLAGS', 'INTERNALDATE']).
              and_return([[nil, @message]])

        subject.fetch(123)
      end

      if RUBY_VERSION > '1.9'
        it 'should set the encoding on the message' do
          @imap.stub!(:examine => nil, :uid_fetch => [[nil, @message]])

          @message_body.should_receive(:force_encoding).with('utf-8')

          subject.fetch(123)
        end
      end

    end

  end

end

