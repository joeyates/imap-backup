# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::FolderChooser do
  include HighLineTestHelpers
  include InputOutputTestHelpers

  context '#run' do
    let(:connection) { double('Imap::Backup::Account::Connection', :folders => remote_folders) }
    let(:account) { {:folders => []} }
    let(:remote_folders) { [] }

    subject { Imap::Backup::Configuration::FolderChooser.new(account) }

    before do
      allow(Imap::Backup::Account::Connection).to receive(:new).with(account).and_return(connection)
      allow(subject).to receive(:system)
    end

    before { @input, @output = prepare_highline }

    context 'display' do
      before { subject.run }

      it 'clears the screen' do
        expect(subject).to have_received(:system).with('clear')
      end

      it 'should show the menu' do
        @output.string.should =~ %r{Add/remove folders}
      end
    end

    context 'folder listing' do
      let(:account) { {:folders => [{:name => 'my_folder'}]} }
      let(:remote_folders) do
        folder1 = double('folder', :name => 'my_folder')       # this one is already backed up
        folder2 = double('folder', :name => 'another_folder')
        [folder1, folder2]
      end

      context 'display' do
        before { subject.run }

        it 'shows folders which are being backed up' do
          expect(@output.string).to include('+ my_folder')
        end

        it 'shows folders which are not being backed up' do
          expect(@output.string).to include('- another_folder')
        end
      end

      context 'adding folders' do
        before do
          allow(@input).to receive(:gets).and_return("2\n", "q\n")

          subject.run
        end

        specify 'are added to the account' do
          expect(account[:folders]).to include({:name => 'another_folder'})
        end
      end

      context 'removing folders' do
        before do
          allow(@input).to receive(:gets).and_return("1\n", "q\n")

          subject.run
        end

        specify 'are removed from the account' do
          expect(account[:folders]).to_not include({:name => 'my_folder'})
        end
      end
    end

    context 'with connection errors' do
      before do
        allow(Imap::Backup::Account::Connection).to receive(:new).with(account).and_raise('error')
        allow(Imap::Backup::Configuration::Setup.highline).to receive(:ask)
        @direct_output = capturing_output { subject.run }
      end

      it 'prints an error message' do
        expect(@direct_output).to include('Connection failed')
      end

      it 'asks to continue' do
        expect(Imap::Backup::Configuration::Setup.highline).to have_received(:ask).with('Press a key ')
      end
    end
  end
end
