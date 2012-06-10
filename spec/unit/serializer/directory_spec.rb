# encoding: utf-8

load File.expand_path('../../spec_helper.rb', File.dirname(__FILE__))

describe Imap::Backup::Serializer::Directory do

  context '#initialize' do

    it 'should fail if download path file permissions are to lax' do
      stat = stub('File::Stat', :mode => 0345)
      File.should_receive(:stat).with('/base/path').and_return(stat)

      expect do
        Imap::Backup::Serializer::Directory.new('/base/path', 'my_folder')
      end.to raise_error(RuntimeError, "Permissions on '/base/path' should be 0700, not 0345")
    end

  end

  context '#uids' do

    before :each do
      stat = stub('File::Stat', :mode => 0700)
      File.stub!(:stat).with('/base/path').and_return(stat)
    end

    subject { Imap::Backup::Serializer::Directory.new('/base/path', 'my_folder') }

    it 'should return the backed-up uids' do
      files = ['00000123.json']

      File.should_receive(:exist?).with('/base/path/my_folder').and_return(true)
      Dir.should_receive(:open).with('/base/path/my_folder').and_return(files)

      subject.uids.should == ['123']
    end

    it 'should return an empty Array if the directory does not exist' do
      File.should_receive(:exist?).with('/base/path/my_folder').and_return(false)

      subject.uids.should == []
    end

  end

end

