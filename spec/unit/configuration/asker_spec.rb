# encoding: utf-8
require 'spec_helper'

module Imap::Backup
  describe Configuration::Asker do
    let(:highline) { double }
    let(:query) do
      double(
        'Query',
        :default= => nil,
        :readline= => nil,
        :validate= => nil,
        :responses => {},
        :echo= => nil,
      )
    end
    let(:answer) { 'foo' }

    before do
      allow(Configuration::Setup).to receive(:highline).and_return(highline)
      allow(highline).to receive(:ask) do |&b|
        b.call query
        answer
      end
    end

    subject { described_class.new(highline) }

    [
      [:email, [], 'email address'],
      [:password, [], 'password'],
      [:backup_path, ['x', 'y'], 'backup directory'],
    ].each do |method, params, prompt|
      context ".#{method}" do
        it 'asks for input' do
          described_class.send(method, *params)

          expect(highline).to have_received(:ask).with("#{prompt}: ")
        end

        it 'returns the answer' do
          expect(described_class.send(method, *params)).to eq(answer)
        end
      end
    end

    context '#initialize' do
      its(:highline) { should eq(highline) }
    end

    context '#email' do
      let(:email) { 'email@example.com' }
      let(:answer) { email }

      before do
        @result = subject.email
      end

      it 'asks for an email'  do
        expect(highline).to have_received(:ask).with(/email/)
      end

      it 'returns the address' do
        expect(@result).to eq(email)
      end
    end

    context '#password' do
      let(:password1) { 'password' }
      let(:password2) { 'password' }
      let(:answers) { [answer1, answer2] }
      let(:answer1) { true }
      let(:answer2) { false }

      before do
        @i = 0
        allow(highline).to receive(:ask).with('password: ').and_return(password1)
        allow(highline).to receive(:ask).with('repeat password: ').and_return(password2)
        allow(highline).to receive(:agree) do
          answer = answers[@i]
          @i += 1
          answer
        end
        @result = subject.password
      end

      it 'asks for a password' do
        expect(highline).to have_received(:ask).with('password: ')
      end

      it 'asks for confirmation' do
        expect(highline).to have_received(:ask).with('repeat password: ')
      end

      it 'returns the password' do
        expect(@result).to eq(password1)
      end

      context 'different answers' do
        let(:password2) { 'secret' }

        it 'asks to continue' do
          expect(highline).to have_received(:agree).at_least(1).times.with(/Continue\?/)
        end
      end
    end

    context '#backup_path' do
      let(:path) { '/path' }
      let(:answer) { path }

      before do
        allow(highline).to receive(:ask) do |&b|
          b.call query
          path
        end
        @result = subject.backup_path('', //)
      end

      it 'asks for a directory' do
        expect(highline).to have_received(:ask).with(/directory/)
      end

      it 'returns the path' do
        expect(@result).to eq(path)
      end
    end
  end
end
