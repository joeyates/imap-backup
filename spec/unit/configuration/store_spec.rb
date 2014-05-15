# encoding: utf-8
require 'spec_helper'
require 'json'

describe Imap::Backup::Configuration::Store do
  let(:directory) { '/base/path' }
  let(:file_path) { File.join(directory, '/config.json') }
  let(:file_exists) { true }
  let(:directory_exists) { true }
  let(:data) { {:the => :config} }
  let(:configuration) { data.to_json }

  before do
    stub_const('Imap::Backup::Configuration::Store::CONFIGURATION_DIRECTORY', directory)
    allow(File).to receive(:directory?).with(directory).and_return(directory_exists)
    allow(File).to receive(:exist?).with(file_path).and_return(file_exists)
    allow(File).to receive(:read).with(file_path).and_return(configuration)
    allow(JSON).to receive(:parse).with(configuration, anything).and_return(data)
  end

  context '.exist?' do
    [true, false].each do |exists|
      state = exists ? 'exists' : "doesn't exist"
      context "when the file #{state}" do
        let(:file_exists) { exists }

        it "returns #{exists}" do
          expect(described_class.exist?).to eq(file_exists)
        end
      end
    end
  end

  context '#path' do
    it 'is the directory containing the configuration file' do
      expect(subject.path).to eq(directory)
    end
  end

  context '#save' do
    let(:directory_exists) { false }
    let(:file_exists) { false }
    let(:file) { double('File', :write => nil) }

    before do
      allow(FileUtils).to receive(:mkdir)
      allow(FileUtils).to receive(:chmod)
      allow(Imap::Backup::Utils).to receive(:stat).with(directory).and_return(0700)
      allow(Imap::Backup::Utils).to receive(:stat).with(file_path).and_return(0600)
      allow(Imap::Backup::Utils).to receive(:check_permissions).and_return(nil)
      allow(File).to receive(:open).with(file_path, 'w') { |&b| b.call file }
      allow(JSON).to receive(:pretty_generate).and_return('JSON output')
    end

    subject { described_class.new }

    it 'creates the config directory' do
      subject.save

      expect(FileUtils).to have_received(:mkdir).with(directory)
    end

    it 'saves the configuration' do
      subject.save

      expect(file).to have_received(:write).with('JSON output')
    end

    it 'sets config perms to 0600' do
      subject.save

      expect(FileUtils).to have_received(:chmod).with(0600, file_path)
    end

    context 'if the configuration file is missing' do
      let(:file_exists) { false }

      it "doesn't fail" do
        expect do
          subject.save
        end.to_not raise_error
      end
    end

    context 'if the config file permissions are too lax' do
      let(:file_exists) { true }

      before do
        allow(Imap::Backup::Utils).to receive(:check_permissions).with(file_path, 0600).and_raise('Error')
      end

      it 'fails' do
        expect do
          subject.save
        end.to raise_error(RuntimeError, 'Error')
      end
    end

    context 'saving accounts' do
      let(:folders) { [{ :name => 'A folder' }] }
      let(:data) do
        {
          :accounts => [
            :local_path => '/my/backup/path',
            :folders    => folders
          ]
        }
      end
      let(:file_exists) { true }
      let(:a_folder_perms) { 0700 }

      before do
        allow(Imap::Backup::Utils).to receive(:check_permissions)
        allow(File).to receive(:directory?).with('/my/backup/path').and_return(false)
        allow(Imap::Backup::Utils).to receive(:stat).with('/my/backup/path').and_return(0700)
        allow(File).to receive(:directory?).with('/my/backup/path/A folder').and_return(false)
        allow(Imap::Backup::Utils).to receive(:stat).with('/my/backup/path/A folder').and_return(a_folder_perms)
      end

      it 'creates account directories' do
        subject.save

        expect(FileUtils).to have_received(:mkdir).with('/my/backup/path')
      end

      it 'creates folder directories' do
        subject.save

        expect(FileUtils).to have_received(:mkdir).with('/my/backup/path/A folder')
      end

      context 'when directory permissions are too open' do
        let(:a_folder_perms) { 0755 }

        it 'sets premissions' do
          subject.save

          expect(FileUtils).to have_received(:chmod).with(0700, '/my/backup/path/A folder')
        end
      end

      context 'when folders have slashes' do
        let(:directory_exists) { true }
        let(:folders) { [{:name => 'folder/path'}] }

        before do
          allow(File).to receive(:directory?).with('/my/backup/path/folder').and_return(true)
          allow(Imap::Backup::Utils).to receive(:stat).with('/my/backup/path/folder').and_return(0700)
          allow(File).to receive(:directory?).with('/my/backup/path/folder/path').and_return(false)
          allow(Imap::Backup::Utils).to receive(:stat).with('/my/backup/path/folder/path').and_return(0700)
          allow(FileUtils).to receive(:mkdir)
        end

        it 'creates subdirectories' do
          subject.save

          expect(FileUtils).to have_received(:mkdir).with('/my/backup/path/folder/path')
        end
      end
    end
  end
end
