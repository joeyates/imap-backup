# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Downloader do
  context 'with account and downloader' do
    let(:local_path) { '/base/path' }
    let(:stat) { double('File::Stat', :mode => 0700) }
    let(:message) do
      {
        'RFC822' => 'the body',
        'other'  => 'xxx'
      }
    end
    let(:folder) { double('Imap::Backup::Account::Folder', :fetch => message) }
    let(:serializer) do
      double(
        'Imap::Backup::Serializer',
        :prepare => nil,
        :exist?  => true,
        :uids    => [],
        :save    => nil,
      )
    end

    before { allow(File).to receive(:stat).with(local_path).and_return(stat) }

    subject { described_class.new(folder, serializer) }

    context '#run' do
      context 'with folder' do
        it 'should list messages' do
          allow(folder).to receive(:uids).and_return([])

          subject.run
        end

        context 'with messages' do
          before :each do
            allow(folder).to receive(:uids).and_return(['123', '999', '1234'])
          end

          it 'skips failed fetches' do
            allow(folder).to receive(:fetch).with('999').and_return(nil)

            subject.run

            expect(serializer).to_not have_received(:save).with('999', anything)
          end

          context 'to download' do
            before :each do
              allow(serializer).to receive(:exist?) do |uid|
                if uid == '123'
                  true
                else
                  false
                end
              end
            end

            it 'requests messages' do
              subject.run

              expect(folder).to have_received(:fetch).with('999')
              expect(folder).to have_received(:fetch).with('1234')
            end

            it 'saves messages' do
              subject.run

              expect(serializer).to have_received(:save).with('999', message)
              expect(serializer).to have_received(:save).with('1234', message)
            end
          end
        end
      end
    end
  end
end
