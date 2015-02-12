# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Downloader do
  describe '#run' do
    let(:message) { 'message' }
    let(:folder) { double('Imap::Backup::Account::Folder', :fetch => message, :name => 'folder') }
    let(:folder_uids) { ['111', '222', '333'] }
    let(:serializer) { double('Imap::Backup::Serializer', :save => nil) }
    let(:serializer_uids) { ['222'] }

    subject { described_class.new(folder, serializer) }

    before do
      allow(folder).to receive(:uids).and_return(folder_uids)
      allow(serializer).to receive(:uids).and_return(serializer_uids)
      allow(folder).to receive(:fetch).with('333').and_return(nil)
      subject.run
    end

    context '#run' do
      context 'fetched messages' do
        it 'are saved' do
          expect(serializer).to have_received(:save).with('111', message)
        end
      end

      context 'messages which are already present' do
        specify 'are skipped' do
          expect(serializer).to_not have_received(:save).with('222', anything)
        end
      end

      context 'failed fetches' do
        specify 'are skipped' do
          expect(serializer).to_not have_received(:save).with('333', anything)
        end
      end
    end
  end
end
