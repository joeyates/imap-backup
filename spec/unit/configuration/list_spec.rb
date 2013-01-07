# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::List do
  let(:configuration_data) do
    {
      :accounts => [
        {
          :username => 'a1@example.com'
        },
        {
          :username => 'a2@example.com',
        },
      ]
    }
  end
  let(:store) { stub('Imap::Backup::Configuration::Store', :data => configuration_data) }

  before do
    Imap::Backup::Configuration::Store.stub!(:new => store)
    Imap::Backup::Configuration::Store.stub!(:exist? => true)
  end

  context '#initialize' do
    it 'fails if the configuration file is missing' do
      Imap::Backup::Configuration::Store.should_receive(:exist?).and_return(false)

      expect {
        Imap::Backup::Configuration::List.new
      }.to raise_error(Imap::Backup::ConfigurationNotFound, /not found/)
    end

    context 'with account parameter' do
      it 'should only create requested accounts' do
        configuration = Imap::Backup::Configuration::List.new(['a2@example.com'])

        configuration.accounts.should == configuration_data[:accounts][1..1]
      end
    end
  end

  context 'instance methods' do
    let(:connection) { stub('Imap::Backup::Account::Connection', :disconnect => nil) }

    subject { Imap::Backup::Configuration::List.new }

    context '#each_connection' do

      it 'should instantiate connections' do
        Imap::Backup::Account::Connection.should_receive(:new).with(configuration_data[:accounts][0]).and_return(connection)
        Imap::Backup::Account::Connection.should_receive(:new).with(configuration_data[:accounts][1]).and_return(connection)

        subject.each_connection{}
      end

      it 'should call the block' do
        Imap::Backup::Account::Connection.stub!(:new).and_return(connection)
        calls = 0

        subject.each_connection do |a|
          calls += 1
          a.should == connection
        end
        calls.should == 2
      end

      it 'should disconnect connections' do
        Imap::Backup::Account::Connection.stub!(:new).and_return(connection)

        connection.should_receive(:disconnect)

        subject.each_connection {}
      end
    end
  end
end

