# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::FolderChooser do

  include HighLineTestHelpers
  include InputOutputTestHelpers

  context '#run' do
    let(:connection) do
      stub('Imap::Backup::Account::Connection')
    end
    let(:existing_account) do
      {
        :folders => [{:name => 'my_folder'}]
      }
    end
    let(:empty_account) do
      {
        :folders => []
      }
    end
    let(:remote_folders) do
      folder1 = stub('folder', :name => 'my_folder')       # this one is already backed up
      folder2 = stub('folder', :name => 'another_folder')
      [folder1, folder2]
    end

    before do
      @input, @output = prepare_highline
    end

    context 'empty account' do
      let(:account) { empty_account }

      subject { Imap::Backup::Configuration::FolderChooser.new(account) }

      before do
        connection.stub!(:folders).and_return([])
        Imap::Backup::Account::Connection.stub!(:new).with(account).and_return(connection)
        subject.stub(:system).with('clear')
      end

      it 'should connect to the account' do
        Imap::Backup::Account::Connection.should_receive(:new).with(account).and_return(connection)

        subject.run
      end

      it 'should handle connection errors' do
        Imap::Backup::Account::Connection.should_receive(:new).with(account).and_raise('error')
        Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with('Press a key ')

        capturing_output do
          subject.run
        end.should =~ /connection failed/i
      end

      it 'should get a list of account folders' do
        connection.should_receive(:folders).and_return([])

        subject.run
      end

      it 'clears the screen' do
        subject.should_receive(:system).with('clear')

        subject.run
      end

      it 'should show the menu' do
        subject.run
        
        @output.string.should =~ %r{Add/remove folders}
      end

      it 'should return to the account menu' do
        @input.should_receive(:gets).and_return("return\n")

        subject.run
        
        @output.string.should =~ %r{return to the account menu}
      end
    end

    context 'folder listing' do
      let(:account) { existing_account }

      subject { Imap::Backup::Configuration::FolderChooser.new(account) }

      before do
        connection.stub!(:folders).and_return(remote_folders)
        Imap::Backup::Account::Connection.stub!(:new).with(account).and_return(connection)
        subject.stub(:system).with('clear')
      end

      it 'should list folders' do
        subject.run
 
        @output.string.should =~ /my_folder/
      end

      it 'should show which folders are already being backed up' do
        subject.run
 
        @output.string.should =~ /\d+\. \+ my_folder/
        @output.string.should =~ /\d+\. \- another_folder/
      end

      it 'should add folders' do
        state = :initial
        @input.stub(:gets) do
          case state
          when :initial
            state = :added
            "2\n"         # choose 'another_folder'
          else
            "q\n"
          end
        end

        subject.run

        @output.string.should =~ /\d+\. \+ another_folder/
        account[:folders].should include({:name => 'another_folder'})
      end

      it 'should remove folders' do
        state = :initial
        @input.stub(:gets) do
          case state
          when :initial
            state = :added
            "1\n"
          else
            "q\n"
          end
        end

        subject.run

        @output.string.should =~ /\d+\. \- my_folder/
        account[:folders].should_not include({:name => 'my_folder'})
      end
    end
  end
end
