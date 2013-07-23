# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Account::Connection do
  let(:imap) { double('Net::IMAP', :login => nil) }
  let(:folder) { double('Imap::Backup::Account::Folder', :uids => []) }

  context '#initialize' do
    it 'should login to the imap server' do
      Net::IMAP.should_receive(:new).with('imap.gmail.com', 993, true).and_return(imap)
      imap.should_receive('login').with('myuser', 'secret')

      Imap::Backup::Account::Connection.new(:username => 'myuser', :password => 'secret')
    end

    context "with specific server" do
      it 'should login to the imap server' do
        Net::IMAP.should_receive(:new).with('my.imap.example.com', 993, true).and_return(imap)
        imap.should_receive('login').with('myuser', 'secret')

        Imap::Backup::Account::Connection.new(:username => 'myuser', :password => 'secret', :server => 'my.imap.example.com')
      end
    end
  end

  context 'instance methods' do
    let(:serializer) { double('Imap::Backup::Serializer', :uids => []) }
    let(:account) do
      {
        :username   => 'myuser',
        :password   => 'secret',
        :folders    => [{:name => 'my_folder'}],
        :local_path => '/base/path',        
      }
    end

    before :each do
      Net::IMAP.stub(:new).and_return(imap)
    end

    subject { Imap::Backup::Account::Connection.new(account) }

    context '#disconnect' do
      it 'should disconnect from the server' do
        imap.should_receive(:disconnect)

        subject.disconnect
      end
    end

    context '#folders' do
      it 'should list all folders' do
        imap.should_receive(:list).with('/', '*')

        subject.folders
      end
    end

    context '#status' do
      before :each do
        Imap::Backup::Account::Folder.stub(:new).with(subject, 'my_folder').and_return(folder)
        Imap::Backup::Serializer::Directory.stub(:new).with('/base/path', 'my_folder').and_return(serializer)
      end

      it 'should return the names of folders' do
        subject.status[0][:name].should == 'my_folder'
      end

      it 'should list local message uids' do
        serializer.should_receive(:uids).and_return([321, 456])

        subject.status[0][:local].should == [321, 456]
      end

      it 'should retrieve the available uids' do
        folder.should_receive(:uids).and_return([101, 234])

        subject.status[0][:remote].should == [101, 234]
      end
    end

    context '#run_backup' do
      let(:downloader) { double('Imap::Backup::Downloader', :run => nil) }

      before :each do
        Imap::Backup::Account::Folder.stub(:new).with(subject, 'my_folder').and_return(folder)
        Imap::Backup::Serializer::Mbox.stub(:new).with('/base/path', 'my_folder').and_return(serializer)
        Imap::Backup::Downloader.stub(:new).with(folder, serializer).and_return(downloader)
      end

      it 'should instantiate folders' do
        Imap::Backup::Account::Folder.should_receive(:new).with(subject, 'my_folder').and_return(folder)

        subject.run_backup
      end

      it 'should instantiate serializers' do
        Imap::Backup::Serializer::Mbox.should_receive(:new).with('/base/path', 'my_folder').and_return(serializer)

        subject.run_backup
      end

      it 'should instantiate downloaders' do
        Imap::Backup::Downloader.should_receive(:new).with(folder, serializer).and_return(downloader)

        subject.run_backup
      end

      it 'should run downloaders' do
        downloader.should_receive(:run)

        subject.run_backup
      end
    end
  end
end

