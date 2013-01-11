# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::Setup do
  include HighLineTestHelpers

  context '#initialize' do
    it 'should not require the config file to exist' do
      Imap::Backup::Configuration::Store.should_receive(:new)

      Imap::Backup::Configuration::Setup.new
    end
  end

  context '#run' do
    before :each do
      prepare_store
      @input, @output = prepare_highline
      subject.stub(:system => nil)
    end

    def prepare_store
      @account1 = { :username => 'account@example.com' }
      @data     = { :accounts => [ @account1 ] }
      @store    = stub('Imap::Backup::Configuration::Store', :data => @data, :path => '/base/path')
      Imap::Backup::Configuration::Store.stub!(:new).and_return(@store)
    end

    subject { Imap::Backup::Configuration::Setup.new }

    it 'should present a main menu' do
      @input.should_receive(:eof?).and_return(false)
      @input.should_receive(:gets).and_return("q\n")

      subject.run

      @output.string.should =~ /Choose an action:/
      @output.string.should =~ /add account/
      @output.string.should =~ /save and exit/
      @output.string.should =~ /quit/
    end

    it 'clears the screen' do
      subject.should_receive(:system).with('clear')

      subject.run
    end

    it 'should list accounts' do
      subject.run

      @output.string.should =~ /account@example.com/
    end

    it 'should edit accounts' do
      state = :initial
      @input.stub(:gets) do
        case state
        when :initial
          state = :editing
          "account@example.com\n"
        else
          "q\n"
        end
      end

      @account = stub('Imap::Backup::Configuration::Account')
      Imap::Backup::Configuration::Account.should_receive(:new).with(@store, @account1).and_return(@account)
      @account.should_receive(:run).with()

      subject.run
    end

    it 'should add accounts' do
      state = :initial
      @input.stub(:gets) do
        case state
        when :initial
          state = :editing
          "add\n"
        else
          "q\n"
        end
      end

      blank_account = {:username=>"new@example.com", :password=>"", :local_path=>"/base/path/new_example.com", :folders=>[]}
      Imap::Backup::Configuration::Asker.should_receive(:email).with().and_return('new@example.com')
      @account = stub('Imap::Backup::Configuration::Account')
      Imap::Backup::Configuration::Account.should_receive(:new).with(@store, blank_account).and_return(@account)
      @account.should_receive(:run).once

      subject.run

      @data[:accounts].size.should == 2
      @data[:accounts][1].should == {
        :username   => "new@example.com",
        :password   => "",
        :local_path => "/base/path/new_example.com",
        :folders    => []
      }
    end

    it 'should save the configuration' do
      @input.should_receive(:gets).with().and_return("save\n")
      @store.should_receive(:save).with()

      subject.run
    end

    it 'should exit' do
      @input.should_receive(:gets).with().and_return("quit\n")

      subject.run
    end
  end
end

