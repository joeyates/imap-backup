# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Configuration do

  before :each do
    @configuration_data = {
      :accounts => [
        {
          :username => 'a1@example.com'
        },
        {
          :username => 'a2@example.com',
        },
      ]
    }
    File.stub!(:exist?).and_return(true)
    stat = stub('File::Stat', :mode => 0600)
    File.stub!(:stat).and_return(stat)
    File.stub!(:read)
    JSON.stub!(:parse).and_return(@configuration_data)
  end

  context '#initialize' do

    it 'should fail if the config file is missing' do
      File.should_receive(:exist?).and_return(false)

      expect do
        Imap::Backup::Configuration.new
      end.to raise_error(RuntimeError, /not found/)
    end

    it 'should fail if the config file permissions are too lax' do
      File.stub!(:exist?).and_return(true)

      stat = stub('File::Stat', :mode => 0644)
      File.should_receive(:stat).and_return(stat)

      expect do
        Imap::Backup::Configuration.new
      end.to raise_error(RuntimeError, /Permissions.*?should be 0600/)
    end

    it 'should load the config file' do
      File.stub!(:exist?).and_return(true)

      stat = stub('File::Stat', :mode => 0600)
      File.stub!(:stat).and_return(stat)

      configuration = 'JSON string'
      File.should_receive(:read).with(%r{/.imap-backup/config.json}).and_return(configuration)
      JSON.should_receive(:parse).with(configuration, :symbolize_names => true)

      Imap::Backup::Configuration.new
    end

    context 'with account parameter' do
      it 'should only create requested accounts' do
        configuration = Imap::Backup::Configuration.new(['a2@example.com'])

        configuration.accounts.should == @configuration_data[:accounts][1..1]
      end
    end

  end

  context 'instance methods' do

    before :each do
      @connection = stub('Imap::Backup::Account::Connection', :disconnect => nil)
    end

    subject { Imap::Backup::Configuration.new }

    context '#each_connection' do

      it 'should instantiate connections' do
        Imap::Backup::Account::Connection.should_receive(:new).with(@configuration_data[:accounts][0]).and_return(@connection)
        Imap::Backup::Account::Connection.should_receive(:new).with(@configuration_data[:accounts][1]).and_return(@connection)

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

  end

end

