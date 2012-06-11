# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Settings do

  before :each do
    @settings = {
      :accounts => [
        {
          :username => 'a1@example.com',
          :local_path => '/base/path',
          :folders => [{:name => 'my_folder'}]
        },
        {
          :username => 'a2@example.com',
          :folders => []
        },
      ]
    }
    File.stub!(:exist?).and_return(true)
    stat = stub('File::Stat', :mode => 0600)
    File.stub!(:stat).and_return(stat)
    File.stub!(:read)
    JSON.stub!(:parse).and_return(@settings)
  end

  context '#initialize' do

    it 'should fail if the config file is missing' do
      File.should_receive(:exist?).and_return(false)

      expect do
        Imap::Backup::Settings.new
      end.to raise_error(RuntimeError, /not found/)
    end

    it 'should fail if the config file permissions are too lax' do
      File.stub!(:exist?).and_return(true)

      stat = stub('File::Stat', :mode => 0644)
      File.should_receive(:stat).and_return(stat)

      expect do
        Imap::Backup::Settings.new
      end.to raise_error(RuntimeError, /Permissions.*?should be 0600/)
    end

    it 'should load the config file' do
      File.stub!(:exist?).and_return(true)

      stat = stub('File::Stat', :mode => 0600)
      File.stub!(:stat).and_return(stat)

      configuration = 'JSON string'
      File.should_receive(:read).with(%r{/.imap-backup/config.json}).and_return(configuration)
      JSON.should_receive(:parse).with(configuration, :symbolize_names => true)

      Imap::Backup::Settings.new
    end

    context 'with account parameter' do
      it 'should only create requested accounts' do
        settings = Imap::Backup::Settings.new(['a2@example.com'])

        settings.accounts.should == @settings[:accounts][1..1]
      end
    end

  end

  context 'instance methods' do

    before :each do
      @connection = stub('Imap::Backup::Account::Connection', :disconnect => nil)
    end

    subject { Imap::Backup::Settings.new }

    context '#each_connection' do

      it 'should instantiate connections' do
        Imap::Backup::Account::Connection.should_receive(:new).with(@settings[:accounts][0]).and_return(@connection)
        Imap::Backup::Account::Connection.should_receive(:new).with(@settings[:accounts][1]).and_return(@connection)

        subject.each_connection{}
      end

      it 'should call the block' do
        Imap::Backup::Account::Connection.stub!(:new).and_return(@connection)
        calls = 0

        subject.each_connection do |a|
          calls += 1
          a.should == @connection
        end
        calls.should == 2
      end

      it 'should disconnect connections' do
        Imap::Backup::Account::Connection.stub!(:new).and_return(@connection)

        @connection.should_receive(:disconnect)

        subject.each_connection {}
      end

    end

    context '#run_backup' do

      before :each do
        Imap::Backup::Account::Connection.stub!(:new).and_return(@connection)
        @folder = stub('Imap::Backup::Account::Folder', :uids => [])
        Imap::Backup::Account::Folder.stub!(:new).with(@connection, 'my_folder').and_return(@folder)
        @serializer = stub('Imap::Backup::Serializer')
        Imap::Backup::Serializer::Directory.stub!(:new).with('/base/path', 'my_folder').and_return(@serializer)
        @downloader = stub('Imap::Backup::Downloader', :run => nil)
        Imap::Backup::Downloader.stub!(:new).with(@folder, @serializer).and_return(@downloader)
      end

      it 'should instantiate connections' do
        Imap::Backup::Account::Connection.should_receive(:new).with(@settings[:accounts][0]).and_return(@connection)
        Imap::Backup::Account::Connection.should_receive(:new).with(@settings[:accounts][1]).and_return(@connection)

        subject.run_backup
      end

      it 'should instantiate folders' do
        Imap::Backup::Account::Folder.should_receive(:new).with(@connection, 'my_folder').and_return(@folder)

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

      it 'should disconnect' do
        @connection.should_receive(:disconnect).twice

        subject.run_backup
      end

    end

  end

end

