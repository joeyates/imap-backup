# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Account do

  context '#initialize' do

    it 'should login to the imap server' do
      imap = stub('Net::IMAP')
      Net::IMAP.should_receive(:new).with('imap.gmail.com', 993, true).and_return(imap)
      imap.should_receive('login').with('myuser', 'secret')

      Imap::Backup::Account.new(:username => 'myuser', :password => 'secret')
    end

  end

  context 'with imap' do
    before :each do
      @imap = stub('Net::IMAP', :login => nil)
      Net::IMAP.stub!(:new).and_return(@imap)
    end

    subject { Imap::Backup::Account.new('username' => 'myuser', 'password' => 'secret') }

    context '#disconnect' do
      it 'should disconnect from the server' do
        @imap.should_receive(:disconnect)

        subject.disconnect
      end
    end

    context '#folders' do
      it 'should list all folders' do
        @imap.should_receive(:list).with('/', '*')

        subject.folders
      end
    end

    context '#each_uid' do
      it 'should examine the folder' do
        @imap.stub!(:uid_search => [])
        @imap.should_receive(:examine).with('my_folder')

        subject.each_uid('my_folder') {}
      end

      it 'should call the block with each message uid' do
        @imap.stub!(:examine).with('my_folder')
        @imap.should_receive(:uid_search).with(['ALL']).and_return(['123', '456'])

        uids = []
        subject.each_uid('my_folder') do |uid|
          uids << uid
        end

        uids.should == ['123', '456']
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
        @imap.should_receive(:uid_fetch).
              with(['123'], ['RFC822', 'FLAGS', 'INTERNALDATE']).
              and_return([[nil, @message]])

        subject.fetch('123')
      end

      if RUBY_VERSION > '1.9'
        it 'should set the encoding on the message' do
          @imap.stub!(:uid_fetch => [[nil, @message]])

          @message_body.should_receive(:force_encoding).with('utf-8')

          subject.fetch('123')
        end
      end

    end

  end

end

