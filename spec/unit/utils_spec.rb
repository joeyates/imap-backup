# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Utils do

  context '#check_permissions' do

    before :each do
      File.stub!(:exist?).and_return(true)
    end

    it 'should stat the file' do
      stat = stub('File::Stat', :mode => 0100)
      File.should_receive(:stat).with('foobar').and_return(stat)

      Imap::Backup::Utils.check_permissions('foobar', 0345)
    end

    it 'should succeed if file permissions are less than limit' do
      stat = stub('File::Stat', :mode => 0100)
      File.stub!(:stat).and_return(stat)

      expect do
        Imap::Backup::Utils.check_permissions('foobar', 0345)
      end.to_not raise_error
    end

    it 'should succeed if file permissions are equal to limit' do
      stat = stub('File::Stat', :mode => 0345)
      File.stub!(:stat).and_return(stat)

      expect do
        Imap::Backup::Utils.check_permissions('foobar', 0345)
      end.to_not raise_error
    end

    it 'should fail if file permissions are over the limit' do
      stat = stub('File::Stat', :mode => 0777)
      File.stub!(:stat).and_return(stat)

      expect do
        Imap::Backup::Utils.check_permissions('foobar', 0345)
      end.to raise_error(RuntimeError, "Permissions on 'foobar' should be 0345, not 0777")
    end

  end

  context '#make_folder' do

    it 'should do nothing if an empty path is supplied' do
      FileUtils.should_not_receive(:mkdir_p)

      Imap::Backup::Utils.make_folder('aaa', '', 0222)
    end

    it 'should create the path' do
      FileUtils.stub!(:chmod)

      FileUtils.should_receive(:mkdir_p).with('/base/path/new/folder')

      Imap::Backup::Utils.make_folder('/base/path', 'new/folder', 0222)
    end

    it 'should set permissions on the path' do
      FileUtils.stub!(:mkdir_p)

      FileUtils.should_receive(:chmod).with(0222, '/base/path/new')

      Imap::Backup::Utils.make_folder('/base/path', 'new/folder', 0222)
    end

  end

end

