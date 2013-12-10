# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Account::Connection do
  def self.folder_config
    {:name => 'backup_folder'}
  end

  let(:imap) { double('Net::IMAP', :login => nil, :list => []) }
  let(:options) do
    {
      :username => username,
      :password => 'password',
      :local_path => 'local_path',
      :folders => [self.class.folder_config]
    }
  end
  let(:username) { 'username@gmail.com' }

  before do
    allow(Net::IMAP).to receive(:new).and_return(imap)
  end

  subject { Imap::Backup::Account::Connection.new(options) }

  shared_examples 'connects to IMAP' do |options|
    options ||= {}
    username = options[:username] || 'username@gmail.com'
    server = options[:server] || 'imap.gmail.com'

    it 'sets up the IMAP connection' do
      expect(Net::IMAP).to have_received(:new).with(server, {:port => 993, :ssl => true})
    end

    it 'logs in to the imap server' do
      expect(imap).to have_received(:login).with(username, 'password')
    end
  end

  context '#initialize' do
    [
      [:username, 'username@gmail.com'],
      [:local_path, 'local_path'],
      [:backup_folders, [folder_config]]
    ].each do |attr, expected|
      its(attr) { should eq(expected) }
    end
  end

  [
    ['GMail', 'user@gmail.com', 'imap.gmail.com'],
    ['Fastmail', 'user@fastmail.fm', 'mail.messagingengine.com'],
  ].each do |service, email_username, server|
    context service do
      let(:username) { email_username }

      before { allow(imap).to receive(:disconnect) }
      before { subject.disconnect }

      include_examples 'connects to IMAP', {:username => email_username, :server => server}
    end
  end

  context '#folders' do
    let(:folders) { 'folders' }

    before { allow(imap).to receive(:list).and_return(folders) }

    it 'returns the list of folders' do
      expect(subject.folders).to eq(folders)
    end
  end

  context '#status' do
    let(:folder) { double('folder', :uids => [remote_uid]) }
    let(:local_uid) { 'local_uid' }
    let(:serializer) { double('serializer', :uids => [local_uid]) }
    let(:remote_uid) { 'remote_uid' }

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new).and_return(folder)
      allow(Imap::Backup::Serializer::Directory).to receive(:new).and_return(serializer)
    end

    it 'should return the names of folders' do
      expect(subject.status[0][:name]).to eq('backup_folder')
    end

    it 'returns local message uids' do
      expect(subject.status[0][:local]).to eq([local_uid])
    end

    it 'should retrieve the available uids' do
      expect(subject.status[0][:remote]).to eq([remote_uid])
    end
  end

  context '#disconnect' do
    before { allow(imap).to receive(:disconnect) }
    before { subject.disconnect }

    it 'disconnects from the server' do
      expect(imap).to have_received(:disconnect).with()
    end

    include_examples 'connects to IMAP'
  end

  context '#run_backup' do
    let(:folder) { double('folder') }
    let(:serializer) { double('serializer') }
    let(:downloader) { double('downloader', :run => nil) }

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new).and_return(folder)
      allow(Imap::Backup::Serializer::Mbox).to receive(:new).and_return(serializer)
      allow(Imap::Backup::Downloader).to receive(:new).and_return(downloader)
    end

    before { subject.run_backup }

    it 'runs downloaders' do
      expect(downloader).to have_received(:run)
    end
  end
end

