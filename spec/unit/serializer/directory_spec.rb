# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Serializer::Directory do
  let(:stat) { stub('File::Stat', :mode => 0700) }
  let(:files) { ['00000123.json', '000001.json'] }

  before do
    File.stub!(:stat).with('/base/path').and_return(stat)
    FileUtils.stub!(:mkdir_p).with('/base/path/my_folder')
    FileUtils.stub!(:chmod).with(0700, '/base/path/my_folder')
    File.stub!(:exist?).with('/base/path').and_return(true)
  end

  subject { Imap::Backup::Serializer::Directory.new('/base/path', 'my_folder') }

  context '#uids' do
    it 'should return the backed-up uids' do
      File.should_receive(:exist?).with('/base/path/my_folder').and_return(true)
      Dir.should_receive(:open).with('/base/path/my_folder').and_return(files)

      subject.uids.should == [1, 123]
    end

    it 'should return an empty Array if the directory does not exist' do
      File.should_receive(:exist?).with('/base/path/my_folder').and_return(false)

      subject.uids.should == []
    end
  end

  context '#exist?' do
    it 'should check if the file exists' do
      File.should_receive(:exist?).with(%r{/base/path/my_folder/0+123.json}).and_return(true)

      subject.exist?(123).should be_true
    end
  end

  context '#save' do
    let(:message) do
      {
        'RFC822' => 'the body',
        'other'  => 'xxx'
      }
    end
    let(:file) { stub('File', :write => nil) }

    before do
      File.stub!(:exist?).with(%r{/base/path/my_folder/0+1234.json}).and_return(true)
      FileUtils.stub!(:chmod).with(0600, /0+1234.json$/)
      File.stub!(:open) do |&block|
        block.call file
      end
    end

    it 'should save messages' do
      File.should_receive(:open) do |&block|
        block.call file
      end
      file.should_receive(:write).with(/the body/)

      subject.save('1234', message)
    end

    it 'should JSON encode messages' do
      message.should_receive(:to_json)

      subject.save('1234', message)
    end

    it 'should set file permissions' do
      FileUtils.should_receive(:chmod).with(0600, /0+1234.json$/)

      subject.save(1234, message)
    end
  end
end

