require 'spec_helper'

describe Email::Provider do
  describe '.for_address' do
    context 'known providers' do
      [['gmail.com', :gmail], ['fastmail.fm', :fastmail]].each do |domain, provider|
        it "recognizes #{provider}" do
          address = "foo@#{domain}"
          expect(described_class.for_address(address).provider).to eq(provider)
        end
      end
    end

    context 'with unknown providers' do
      it 'returns a default provider' do
        expect(described_class.for_address('foo@unknown.com').provider).to eq(:default)
      end
    end
  end

  subject { described_class.new(:gmail) }

  describe '#options' do
    it 'returns options' do
      expect(subject.options).to eq(port: 993, ssl: true)
    end
  end

  describe '#host' do
    it 'returns host' do
      expect(subject.host).to eq('imap.gmail.com')
    end
  end

  describe '#root' do
    it 'returns root' do
      expect(subject.root).to eq('/')
    end
  end
end
