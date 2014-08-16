# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Serializer::Directory do
  let(:stat) { double('File::Stat', :mode => 0700) }
  let(:files) { ['00000123.json', '000001.json'] }
  let(:base) { '/base/path' }
  let(:folder) { '/base/path/my_folder' }
  let(:folder_exists) { true }

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:chmod)
    allow(File).to receive(:stat).with(base).and_return(stat)
    allow(File).to receive(:exist?).with(base).and_return(true)
    allow(File).to receive(:exist?).with(folder).and_return(folder_exists)
  end

  subject { described_class.new(base, 'my_folder') }

  context '#uids' do
    before do
      allow(Dir).to receive(:open).with(folder).and_return(files)
    end

    it 'returns the backed-up uids' do
      expect(subject.uids).to eq([1, 123])
    end

    context 'if the directory does not exist' do
      let(:folder_exists) { false }

      it 'returns an empty array' do
        expect(subject.uids).to eq([])
      end
    end
  end

  context '#exist?' do
    it 'checks if the file exists' do
      allow(File).to receive(:exist?).with(%r{/base/path/my_folder/0+123.json}).and_return(true)

      expect(subject.exist?(123)).to be_truthy
    end
  end

  context '#save' do
    let(:message) { {'RFC822' => 'the body', 'other'  => 'xxx'} }
    let(:file) { double('File', :write => nil) }

    before do
      allow(File).to receive(:exist?).with(%r{/base/path/my_folder/0+1234.json}).and_return(true)
      allow(File).to receive(:open) do |&block|
        block.call file
      end
    end

    it 'saves messages' do
      subject.save('1234', message)

      expect(file).to have_received(:write).with(message.to_json)
    end

    it 'sets file permissions' do
      subject.save(1234, message)

      expect(FileUtils).to have_received(:chmod).with(0600, /0+1234.json$/)
    end
  end
end
