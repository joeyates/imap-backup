# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::Account do
  class MockHighlineMenu
    attr_reader :choices
    attr_accessor :header

    def initialize
      @choices = {}
    end

    def choice(name, &block)
      choices[name] = block
    end

    def hidden(name, &block)
      choices[name] = block
    end
  end

  context '#run' do
    let(:highline) { double('Highline') }
    let(:menu) { MockHighlineMenu.new }
    let(:store) { double('Imap::Backup::Configuration::Store', :data => data) }
    let(:data) { {:accounts => [account, account1]} }
    let(:account) do
      {
        :username => existing_email,
        :server => existing_server,
        :local_path => '/backup/path',
        :folders => [{:name => 'my_folder'}],
        :password => existing_password,
      }
    end
    let(:account1) do
      {
        :username => other_email,
        :local_path => other_existing_path,
      }
    end
    let(:existing_email) { 'user@example.com' }
    let(:new_email) { 'foo@example.com' }
    let(:existing_server) { 'imap.example.com' }
    let(:existing_password) { 'password' }
    let(:other_email) { 'other@example.com' }
    let(:other_existing_path) { '/other/existing/path' }

    before do
      allow(subject).to receive(:system).and_return(nil)
      allow(subject).to receive(:puts).and_return(nil)
      allow(highline).to receive(:choose) do |&block|
        block.call(menu)
        throw :done
      end
    end

    subject { described_class.new(store, account, highline) }

    context 'preparation' do
      before { subject.run }

      it 'clears the screen' do
        expect(subject).to have_received(:system).with('clear')
      end

      context 'menu' do
        it 'shows the menu' do
          expect(highline).to have_received(:choose)
        end
      end
    end

    context 'menu' do
      [
        'modify email',
        'modify password',
        'modify server',
        'modify backup path',
        'choose backup folders',
        'test authentication',
        'delete',
        'return to main menu',
        'quit', # TODO: quit is hidden
      ].each do |item|
        before { subject.run }

        it "has a '#{item}' item" do
          expect(menu.choices).to include(item)
        end
      end
    end

    context 'account details' do
      [
        ['email', /email:\s+user@example.com/],
        ['server', /server:\s+imap.example.com/],
        ['password', /password:\s+x+/],
        ['path', %r(path:\s+/backup/path)],
        ['folders', /folders:\s+my_folder/],
      ].each do |attribute, value|
        before { subject.run }

        it "shows the #{attribute}" do
          expect(menu.header).to match(value)
        end
      end

      context 'with no password' do
        let(:existing_password) { '' }

        before { subject.run }

        it 'indicates that a password is not set' do
          expect(menu.header).to include('password: (unset)')
        end
      end
    end

    context 'email' do
      before do
        allow(Imap::Backup::Configuration::Asker).to receive(:email).and_return(new_email)
        subject.run
        menu.choices['modify email'].call
      end

      context 'if the server is blank' do
        [
          ['GMail', 'foo@gmail.com', 'imap.gmail.com'],
          ['Fastmail', 'bar@fastmail.fm', 'mail.messagingengine.com'],
        ].each do |service, email, expected|
          context service do
            let(:new_email) { email }

            context 'with nil' do
              let(:existing_server) { nil }

              it 'sets a default server' do
                expect(account[:server]).to eq(expected)
              end
            end

            context 'with an empty string' do
              let(:existing_server) { '' }

              it 'sets a default server' do
                expect(account[:server]).to eq(expected)
              end
            end
          end
        end
      end

      it 'modifies the email address' do
        expect(account[:username]).to eq(new_email)
      end

      context 'the email already exists' do
        let(:new_email) { other_email }

        it 'indicates the error' do
          expect(subject).to have_received(:puts).with('There is already an account set up with that email address')
        end

        it "doesn't set the email" do
          expect(account[:username]).to eq(existing_email)
        end
      end
    end

    context 'password' do
      let(:new_password) { 'new_password' }

      before do
        allow(Imap::Backup::Configuration::Asker).to receive(:password).and_return(new_password)
        subject.run
        menu.choices['modify password'].call
      end

      it 'updates the password' do
        expect(account[:password]).to eq(new_password)
      end

      context 'if the user cancels' do
        let(:new_password) { nil }

        it 'does nothing' do
          expect(account[:password]).to eq(existing_password)
        end
      end
    end

    context 'server' do
      let(:server) { 'server' }

      before do
        allow(highline).to receive(:ask).with('server: ').and_return(server)
      end

      before do
        subject.run
        menu.choices['modify server'].call
      end

      it 'updates the server' do
        expect(account[:server]).to eq(server)
      end
    end

    context 'backup_path' do
      let(:new_backup_path) { '/new/path' }

      before do
        @validator = nil
        allow(Imap::Backup::Configuration::Asker).to receive(:backup_path) do |path, validator|
          @validator = validator
          new_backup_path
        end
        subject.run
        menu.choices['modify backup path'].call
      end

      it 'updates the path' do
        expect(account[:local_path]).to eq(new_backup_path)
      end

      it 'validates that the path is not used by other backups' do
        expect(@validator.call(other_existing_path)).to be_false
      end
    end

    context 'folders' do
      let(:chooser) { double(:run => nil) }

      before do
        allow(Imap::Backup::Configuration::FolderChooser).to receive(:new).and_return(chooser)
        subject.run
        menu.choices['choose backup folders'].call
      end

      it 'edits folders' do
        expect(chooser).to have_received(:run)
      end
    end

    context 'connection test' do
      before do
        allow(Imap::Backup::Configuration::ConnectionTester).to receive(:test).and_return('All fine')
        allow(highline).to receive(:ask)
        subject.run
        menu.choices['test connection'].call
      end

      it 'tests the connection' do
        expect(Imap::Backup::Configuration::ConnectionTester).to have_received(:test).with(account)
      end
    end

    context 'deletion' do
      let(:confirmed) { true }

      before do
        allow(highline).to receive(:agree).and_return(confirmed)
        subject.run
        catch :done do
          menu.choices['delete'].call
        end
      end

      it 'asks for confirmation' do
        expect(highline).to have_received(:agree)
      end

      it 'deletes the account' do
        expect(data[:accounts].find{|a| a[:username] == existing_email}).to be_nil
      end

      context 'without confirmation' do
        let(:confirmed) { false }

        it 'does nothing' do
          expect(data[:accounts].find{|a| a[:username] == existing_email}).to eq(account)
        end
      end
    end
  end
end
