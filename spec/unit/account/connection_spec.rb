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

  context 'instance methods' do

    before :each do
      @imap = stub('Net::IMAP', :login => nil)
      Net::IMAP.stub!(:new).and_return(@imap)
      @account = {
        :username   => 'myuser',
        :password   => 'secret',
        :folders    => [{:name => 'my_folder'}],
        :local_path => '/base/path',        
      }
    end

    subject { Imap::Backup::Account::Connection.new(@account) }

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


    context '#status' do

      before :each do
        @folder = stub('Imap::Backup::Account::Folder', :uids => [])
        Imap::Backup::Account::Folder.stub!(:new).with(subject, 'my_folder').and_return(@folder)
        @serializer = stub('Imap::Backup::Serializer', :uids => [])
        Imap::Backup::Serializer::Directory.stub!(:new).with('/base/path', 'my_folder').and_return(@serializer)
      end

      it 'should return the names of folders' do
        subject.status[0][:name].should == 'my_folder'
      end

      it 'should list local message uids' do
        @serializer.should_receive(:uids).and_return([321, 456])

        subject.status[0][:local].should == [321, 456]
      end

      it 'should retrieve the available uids' do
        @folder.should_receive(:uids).and_return([101, 234])

        subject.status[0][:remote].should == [101, 234]
      end

    end

    context '#run_backup' do

      before :each do
        @folder = stub('Imap::Backup::Account::Folder', :uids => [])
        Imap::Backup::Account::Folder.stub!(:new).with(subject, 'my_folder').and_return(@folder)
        @serializer = stub('Imap::Backup::Serializer')
        Imap::Backup::Serializer::Directory.stub!(:new).with('/base/path', 'my_folder').and_return(@serializer)
        @downloader = stub('Imap::Backup::Downloader', :run => nil)
        Imap::Backup::Downloader.stub!(:new).with(@folder, @serializer).and_return(@downloader)
      end

      it 'should instantiate folders' do
        Imap::Backup::Account::Folder.should_receive(:new).with(subject, 'my_folder').and_return(@folder)

        subject.run_backup
      end

      it 'should instantiate serializers' do
        Imap::Backup::Serializer::Directory.should_receive(:new).with('/base/path', 'my_folder').and_return(@serializer)

        subject.run_backup
      end

      it 'should instantiate downloaders' do
        Imap::Backup::Downloader.should_receive(:new).with(@folder, @serializer).and_return(@downloader)

        subject.run_backup
      end

      it 'should run downloaders' do
        @downloader.should_receive(:run)

        subject.run_backup
      end

    end

  end

end

