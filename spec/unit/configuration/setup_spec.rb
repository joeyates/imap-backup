# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::Setup do
  include HighLineTestHelpers

  context '#initialize' do
    context 'without a config file' do
      it 'works' do
        described_class.new
      end
    end
  end

  context '#run' do
    let(:account1) { {:username => 'account@example.com'} }
    let(:account) { double('Imap::Backup::Configuration::Account', :run => nil) }
    let(:data) { {:accounts => [account1]} }
    let(:store) do
      double(
        'Imap::Backup::Configuration::Store',
        :data => data,
        :path => '/base/path',
        :save => nil
      )
    end

    before :each do
      allow(Imap::Backup::Configuration::Store).to receive(:new).and_return(store)
      @input, @output = prepare_highline
      allow(@input).to receive(:eof?).and_return(false)
      allow(@input).to receive(:gets).and_return("q\n")
      allow(subject).to receive(:system)
    end

    subject { described_class.new }

    context 'main menu' do
      before { subject.run }

      %w(add\ account save\ and\ exit quit).each do |choice|
        it "includes #{choice}" do
          expect(@output.string).to include(choice)
        end
      end
    end

    it 'clears the screen' do
      subject.run

      expect(subject).to have_received(:system).with('clear')
    end

    it 'should list accounts' do
      subject.run

      expect(@output.string).to match /account@example.com/
    end

    context 'adding accounts' do
      let(:blank_account) do
        {
          :username => "new@example.com",
          :password => "",
          :local_path => "/base/path/new_example.com",
          :folders => []
        }
      end

      before do
        allow(@input).to receive(:gets).and_return("add\n", "q\n")
        allow(Imap::Backup::Configuration::Asker).to receive(:email).with(no_args).and_return('new@example.com')
        allow(Imap::Backup::Configuration::Account).to receive(:new).with(store, blank_account, anything).and_return(account)

        subject.run
      end

      it 'adds account data' do
        expect(data[:accounts][1]).to eq(blank_account)
      end
    end

    it 'should save the configuration' do
      allow(@input).to receive(:gets).and_return("save\n")

      subject.run

      expect(store).to have_received(:save)
    end

    it 'should exit' do
      allow(@input).to receive(:gets).and_return("quit\n")

      subject.run
    end
  end
end
