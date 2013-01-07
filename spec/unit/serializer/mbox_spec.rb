# encoding: utf-8

require 'spec_helper'

describe Imap::Backup::Serializer::Mbox do
  let(:stat) { stub('File::Stat', :mode => 0700) }
  let(:mbox_pathname) { '/base/path/my/folder.mbox' }
  let(:imap_pathname) { '/base/path/my/folder.imap' }

  before do
    File.stub(:exist?).with('/base/path').and_return(true)
    File.stub!(:stat).with('/base/path').and_return(stat)
    Imap::Backup::Utils.stub(:make_folder)
  end

  context '#initialize' do
    before do
      File.stub(:exist?).with(mbox_pathname).and_return(true)
      File.stub(:exist?).with(imap_pathname).and_return(true)
    end

    it 'creates the containing directory' do
      Imap::Backup::Utils.should_receive(:make_folder).with('/base/path', 'my', 0700)

      Imap::Backup::Serializer::Mbox.new('/base/path', 'my/folder')
    end

    context 'mbox and imap files' do
      it 'checks if they exist' do
        File.should_receive(:exist?).with(mbox_pathname).and_return(true)
        File.should_receive(:exist?).with(imap_pathname).and_return(true)

        Imap::Backup::Serializer::Mbox.new('/base/path', 'my/folder')
      end

      it "fails if mbox exists and imap doesn't" do
        File.stub(:exist?).with(imap_pathname).and_return(false)

        expect {
          Imap::Backup::Serializer::Mbox.new('/base/path', 'my/folder')
        }.to raise_error(RuntimeError, '.imap file missing')
      end

      it "fails if imap exists and mbox doesn't" do
        File.stub(:exist?).with(mbox_pathname).and_return(false)

        expect {
          Imap::Backup::Serializer::Mbox.new('/base/path', 'my/folder')
        }.to raise_error(RuntimeError, '.mbox file missing')
      end
    end
  end

  context 'instance methods' do
    before do
      File.stub(:exist?).with(mbox_pathname).and_return(true)
      File.stub(:exist?).with(imap_pathname).and_return(true)
      CSV.stub(:foreach) do |&block|
        block.call ['1']
        block.call ['123']
      end
    end

    subject { Imap::Backup::Serializer::Mbox.new('/base/path', 'my/folder') }

    context '#uids' do
      it 'returns the backed-up uids' do
        File.should_receive(:exist?).with(mbox_pathname).and_return(true)
        File.should_receive(:exist?).with(imap_pathname).and_return(true)

        expect(subject.uids).to eq(['1', '123'])
      end

      it 'returns an empty Array if the mbox does not exist' do
        File.stub(:exist?).with(mbox_pathname).and_return(false)
        File.stub(:exist?).with(imap_pathname).and_return(false)
        File.should_receive(:exist?).with(mbox_pathname).and_return(false)
        File.should_receive(:exist?).with(imap_pathname).and_return(false)

        expect(subject.uids).to eq([])
      end
    end

    context '#save' do
      let(:mbox_formatted_message) { 'message in mbox format' }
      let(:message_uid) { '999' }
      let(:message) { stub('Email::Mboxrd::Message', to_s: mbox_formatted_message) }
      let(:mbox_file) { stub('File - mbox', close: nil) }
      let(:imap_file) { stub('File - imap', close: nil) }

      before do
        Email::Mboxrd::Message.stub(new: message)
        File.stub(:open).with(mbox_pathname, 'ab').and_return(mbox_file)
        File.stub(:open).with(imap_pathname, 'ab').and_return(imap_file)
        mbox_file.stub(:write).with(mbox_formatted_message)
        imap_file.stub(:write).with(message_uid + "\n")
      end

      it 'saves the message to the mbox' do
        mbox_file.should_receive(:write).with(mbox_formatted_message)

        subject.save(message_uid, "The\nemail\n")
      end

      it 'saves the uid to the imap file' do
        imap_file.should_receive(:write).with(message_uid + "\n")

        subject.save(message_uid, "The\nemail\n")
      end
    end
  end
end

