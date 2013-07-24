# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Account::Connection do
  let(:imap) { double('Net::IMAP', :login => nil, :disconnect => nil, :list => []) }
  let(:folder) { double('Imap::Backup::Account::Folder', :uids => []) }

  before do
    Net::IMAP.stub(:new).with(anything, 993, true).and_return(imap)
  end

  context '#initialize' do
    it 'should login to the imap server' do
      Imap::Backup::Account::Connection.new(:username => 'myuser', :password => 'secret')

      expect(imap).to have_received(:login).with('myuser', 'secret')
    end

    context "with specific server" do
      it 'should login to the imap server' do
        Imap::Backup::Account::Connection.new(:username => 'myuser', :password => 'secret', :server => 'my.imap.example.com')

        expect(Net::IMAP).to have_received(:new).with('my.imap.example.com', 993, true)
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

    subject { Imap::Backup::Account::Connection.new(account) }

    context '#disconnect' do
      it 'should disconnect from the server' do
        subject.disconnect

        expect(imap).to have_received(:disconnect).with()
      end
    end

    context '#folders' do
      it 'should list all folders' do
        subject.folders

        expect(imap).to have_received(:list).with('/', '*')
      end
    end

    context '#status' do
      before :each do
        Imap::Backup::Account::Folder.stub(:new).with(subject, 'my_folder').and_return(folder)
        Imap::Backup::Serializer::Directory.stub(:new).with('/base/path', 'my_folder').and_return(serializer)
      end

      it 'requests uids' do
        subject.status

        expect(serializer).to have_received(:uids).with()
      end

      it 'should return the names of folders' do
        expect(subject.status[0][:name]).to eq('my_folder')
      end

      it 'should list local message uids' do
        serializer.stub(:uids).and_return([321, 456])

        puts "subject.status: #{subject.status.inspect}"
        subject.status[0][:local].should == [321, 456]
      end

      it 'should retrieve the available uids' do
        folder.stub(:uids).and_return([101, 234])

        expect(subject.status[0][:remote]).to eq([101, 234])
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

