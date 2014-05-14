# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::List do
  let(:accounts) do
    [
      {:username => 'a1@example.com'},
      {:username => 'a2@example.com'},
    ]
  end
  let(:store) do
    double('Imap::Backup::Configuration::Store', :data => {:accounts => accounts})
  end
  let(:exists) { true }

  before do
    allow(Imap::Backup::Configuration::Store).to receive(:new).and_return(store)
    allow(Imap::Backup::Configuration::Store).to receive(:exist?).and_return(exists)
  end

  subject { described_class.new }

  context '#initialize' do
    context 'with account parameter' do
      subject { described_class.new(['a2@example.com']) }

      it 'should only create requested accounts' do
        expect(subject.accounts).to eq([accounts[1]])
      end
    end

    context 'without an account parameter' do
      it 'selects all accounts' do
        expect(subject.accounts).to eq(accounts)
      end
    end

    context 'when the configuration file is missing' do
      let(:exists) { false }

      it 'fails' do
        expect {
          described_class.new
        }.to raise_error(Imap::Backup::ConfigurationNotFound, /not found/)
      end
    end
  end

  context 'instance methods' do
    let(:connection1) { double('Imap::Backup::Account::Connection', :disconnect => nil) }
    let(:connection2) { double('Imap::Backup::Account::Connection', :disconnect => nil) }

    before do
      allow(Imap::Backup::Account::Connection).to receive(:new).with(accounts[0]).and_return(connection1)
      allow(Imap::Backup::Account::Connection).to receive(:new).with(accounts[1]).and_return(connection2)
    end

    context '#each_connection' do
      specify "calls the block with each account's connection" do
        connections = []

        subject.each_connection { |a| connections << a }

        expect(connections).to eq([connection1, connection2])
      end
    end
  end
end
