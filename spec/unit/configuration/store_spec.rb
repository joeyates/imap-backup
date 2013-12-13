# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::Store do
  before :all do
    @configuration_directory = Imap::Backup::Configuration::Store::CONFIGURATION_DIRECTORY
    Imap::Backup::Configuration::Store.instance_eval { remove_const :'CONFIGURATION_DIRECTORY' }
    Imap::Backup::Configuration::Store::CONFIGURATION_DIRECTORY = '/base/path'
  end

  after :all do
    Imap::Backup::Configuration::Store.instance_eval { remove_const :'CONFIGURATION_DIRECTORY' }
    Imap::Backup::Configuration::Store::CONFIGURATION_DIRECTORY = @configuration_directory
  end

  context '.exist?' do
    it 'checks if the file exists' do
      File.should_receive(:exist?).with('/base/path/config.json').and_return(true)

      Imap::Backup::Configuration::Store.exist?
    end
  end

  context '#initialize' do
    before :each do
      Imap::Backup::Utils.stub!(:check_permissions => nil)
    end

    it 'should not fail if the configuration file is missing' do
      File.should_receive(:directory?).with('/base/path').and_return(true)
      File.should_receive(:exist?).with('/base/path/config.json').and_return(false)

      expect do
        Imap::Backup::Configuration::Store.new
      end.to_not raise_error
    end

    it 'should fail if the config file permissions are too lax' do
      File.stub!(:exist?).with('/base/path/config.json').and_return(true)

      Imap::Backup::Utils.should_receive(:check_permissions).with('/base/path/config.json', 0600).and_raise('Error')

      expect do
        Imap::Backup::Configuration::Store.new
      end.to raise_error(RuntimeError, 'Error')
    end

    it 'should load the config file' do
      File.stub!(:exist?).with('/base/path/config.json').and_return(true)

      configuration = 'JSON string'
      File.should_receive(:read).with('/base/path/config.json').and_return(configuration)
      JSON.should_receive(:parse).with(configuration, :symbolize_names => true)

      Imap::Backup::Configuration::Store.new
    end
  end

  context '#save' do
    before :each do
      # initialize
      File.stub!(:directory?).with('/base/path').and_return(false)
      File.stub!(:exist?).with('/base/path/config.json').and_return(false)
      # save
      @file = stub('File')
      File.stub!(:directory?).with('/base/path').and_return(false)
      FileUtils.stub!(:mkdir).with('/base/path')
      Imap::Backup::Utils.stub!(:stat).with('/base/path').and_return(0700)
      FileUtils.stub!(:chmod).with(0700, '/base/path')
      File.stub!(:open).with('/base/path/config.json', 'w') { |&b| b.call @file }
      JSON.stub!(:pretty_generate => 'JSON output')
      @file.stub!(:write).with('JSON output')
      FileUtils.stub!(:chmod).with(0600, '/base/path/config.json')
    end

    subject { Imap::Backup::Configuration::Store.new }

    it 'should create the config directory' do
      File.should_receive(:directory?).with('/base/path').and_return(false)
      FileUtils.should_receive(:mkdir).with('/base/path')

      subject.save
    end

    it 'should save the config file' do
      @file.should_receive(:write).with('JSON output')

      subject.save
    end

    it 'should set config perms to 0600' do
      FileUtils.should_receive(:chmod).with(0600, '/base/path/config.json')

      subject.save
    end

    context 'saving accounts' do
      before :each do
        # initialize
        File.stub!(:exist?).with('/base/path/config.json').and_return(true)
        Imap::Backup::Utils.stub!(:check_permissions).with('/base/path/config.json', 0600)
        folders = [
          { :name => 'A folder' },
        ]
        File.stub!(:read).with('/base/path/config.json').and_return('xxx')
        JSON.stub!(:parse).with('xxx', :symbolize_names => true).and_return(configuration(folders))
        # save
        File.stub!(:directory?).with('/my/backup/path').and_return(false)
        FileUtils.stub!(:mkdir).with('/my/backup/path')
        Imap::Backup::Utils.stub!(:stat).with('/my/backup/path').and_return(0700)
        File.stub!(:directory?).with('/my/backup/path/A folder').and_return(false)
        FileUtils.stub!(:mkdir).with('/my/backup/path/A folder')
        Imap::Backup::Utils.stub!(:stat).with('/my/backup/path/A folder').and_return(0700)
      end

      def configuration(folders)
        {
          :accounts => [
            :local_path => '/my/backup/path',
            :folders    => folders
          ]
        }
      end

      subject { Imap::Backup::Configuration::Store.new }

      it 'should create account directories' do
        File.should_receive(:directory?).with('/my/backup/path').and_return(false)
        FileUtils.should_receive(:mkdir).with('/my/backup/path')

        subject.save
      end

      it 'should create folder directories' do
        File.should_receive(:directory?).with('/my/backup/path/A folder').and_return(false)
        FileUtils.should_receive(:mkdir).with('/my/backup/path/A folder')

        subject.save
      end

      it 'should set directory permissions, if necessary' do
        Imap::Backup::Utils.stub!(:stat).with('/my/backup/path/A folder').and_return(0755)
        FileUtils.should_receive(:chmod).with(0700, '/my/backup/path/A folder')

        subject.save
      end

      it 'should create a path for folders with slashes' do
        folders = [{:name => 'folder/path'}]
        JSON.stub!(:parse).with('xxx', :symbolize_names => true).and_return(configuration(folders))

        File.should_receive(:directory?).with('/my/backup/path/folder').and_return(true)
        Imap::Backup::Utils.should_receive(:stat).with('/my/backup/path/folder').and_return(0700)
        File.should_receive(:directory?).with('/my/backup/path/folder/path').and_return(true)
        Imap::Backup::Utils.should_receive(:stat).with('/my/backup/path/folder/path').and_return(0700)

        subject.save
      end
    end
  end
end
