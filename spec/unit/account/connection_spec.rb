# encoding: utf-8
load File.expand_path( '../../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Account::Connection do

  context '#initialize' do

    it 'should login to the imap server' do
      imap = stub('Net::IMAP')
      Net::IMAP.should_receive(:new).with('imap.gmail.com', 993, true).and_return(imap)
      imap.should_receive('login').with('myuser', 'secret')

      Imap::Backup::Account::Connection.new(:username => 'myuser', :password => 'secret')
    end

  end

  context 'with imap' do
    before :each do
      @imap = stub('Net::IMAP', :login => nil)
      Net::IMAP.stub!(:new).and_return(@imap)
    end

    subject { Imap::Backup::Account::Connection.new('username' => 'myuser', 'password' => 'secret') }

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

  end

end

