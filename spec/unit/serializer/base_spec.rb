# encoding: utf-8

require 'spec_helper'

describe Imap::Backup::Serializer::Base do
  context '#initialize' do
    let(:stat) { stub('File::Stat', :mode => 0345) }

    it 'should fail if file permissions are to lax' do
      File.stub!(:exist?).with('/base/path').and_return(true)
      File.should_receive(:stat).with('/base/path').and_return(stat)

      expect do
        Imap::Backup::Serializer::Base.new('/base/path', 'my_folder')
      end.to raise_error(RuntimeError, "Permissions on '/base/path' should be 0700, not 0345")
    end
  end
end
