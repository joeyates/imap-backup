# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::Account do
  include HighLineTestHelpers
  include InputOutputTestHelpers

  def choose_menu_item(item)
    @state = :initial
    @input.should_receive(:gets) do
      case @state
      when :initial
        @state = :done
        "#{item}\n"
      when :done
        "quit\n"
      end
    end
  end

  context '#run' do
    before :each do
      @account1_path = '/backup/path'
      @account1 = {
        :username   => 'user@example.com',
        :password   => 'secret',
        :local_path => @account1_path,
        :folders    => [ { :name => 'my_folder' }, { :name => 'another_folder' } ]
      }
      @other_account_path = '/existing/path'
      @other_account = {
        :username   => 'existing@example.com',
        :password   => 'secret',
        :local_path => @other_account_path,
        :folders    => []
      }
      @data = {:accounts => [@account1, @other_account]}
      @store = stub('Imap::Backup::Configuration::Store')
      @store.stub!(:data => @data)
      @input, @output = prepare_highline
    end

    subject { Imap::Backup::Configuration::Account.new(@store, @account1) }

    context 'menu' do
      it 'should show a menu' do
        subject.run

        @output.string.should =~ /modify email/
        @output.string.should =~ /modify password/
        @output.string.should =~ /modify backup path/
        @output.string.should =~ /choose backup folders/
        @output.string.should =~ /test authentication/
        @output.string.should =~ /delete/
        @output.string.should =~ /return to main/
      end

      it 'should show account details in the menu' do
        subject.run

        @output.string.should =~ /email:\s+user@example.com/
        @output.string.should =~ /password:\s+x+/
        @output.string.should =~ %r{path:\s+/backup/path}
        @output.string.should =~ /folders:\s+my_folder, another_folder/
      end

      it 'should indicate that a password is not set' do
        @account1[:password] = ''

        subject.run

        @output.string.should =~ /password:\s+\(unset\)/
      end

    end

    context 'email' do
      it 'should modify the email address' do
        Imap::Backup::Configuration::Asker.should_receive(:email).once.and_return('new@example.com')

        choose_menu_item 'modify email'

        subject.run

        @output.string.should =~ /email:\s+new@example.com/
        @account1[:username].should == 'new@example.com'
      end

      it 'should do nothing if it creates a duplicate' do
        Imap::Backup::Configuration::Asker.should_receive(:email).once.and_return('existing@example.com')

        choose_menu_item 'modify email'

        capturing_output do
          subject.run
        end.should =~ /there is already an account set up with that email address/i
      end
    end

    context 'password' do
      it 'should update the password' do
        Imap::Backup::Configuration::Asker.should_receive(:password).once.and_return('new_pwd')

        choose_menu_item 'modify password'

        subject.run

        @account1[:password].should == 'new_pwd'
      end

      it 'should do nothing if the user cancels' do
        Imap::Backup::Configuration::Asker.should_receive(:password).once.and_return(nil)

        choose_menu_item 'modify password'

        subject.run

        @account1[:password].should == 'secret'
      end
    end

    context 'backup_path' do
      it 'should update the path' do
        Imap::Backup::Configuration::Asker.should_receive(:backup_path).once do |default, validator|
          validator.call('new/path')
          '/new/path'
        end

        choose_menu_item 'modify backup path'

        subject.run

        @account1[:local_path].should == '/new/path'
      end

      it 'should validate that the path is not used by other backups' do
        Imap::Backup::Configuration::Asker.should_receive(:backup_path) do |default, validator|
          validator.call(@other_account_path)
          '/path'
        end

        choose_menu_item 'modify backup path'

        capturing_output do
          subject.run
        end.should =~ %r{The path '/existing/path' is used to backup the account 'existing@example.com'}
      end
    end

    it 'should add/remove folders' do
      @chooser = stub('Imap::Backup::Configuration::FolderChooser')
      Imap::Backup::Configuration::FolderChooser.should_receive(:new).with(@account1).and_return(@chooser)
      @chooser.should_receive(:run).with().once

      choose_menu_item 'choose backup folders'

      subject.run
    end

    it 'should allow testing the connection' do
      Imap::Backup::Configuration::ConnectionTester.should_receive(:test).with(@account1).and_return('All fine')

      choose_menu_item 'test authentication'

      capturing_output do
        subject.run
      end.should == "All fine\n"
    end

    context 'deletion' do
      it 'should confirm deletion' do
        Imap::Backup::Configuration::Setup.highline.should_receive(:agree).with("Are you sure? (y/n) ").and_return(true)

        choose_menu_item 'delete'

        subject.run
      end

      it 'should delete the account' do
        Imap::Backup::Configuration::Setup.highline.stub!(:agree).with("Are you sure? (y/n) ").and_return(true)

        choose_menu_item 'delete'

        subject.run

        @data[:accounts].should_not include(@account1)
      end

      it 'should not delete if confirmation is not given' do
        Imap::Backup::Configuration::Setup.highline.stub!(:agree).with("Are you sure? (y/n) ").and_return(false)

        choose_menu_item 'delete'

        subject.run

        @data[:accounts].should include(@account1)
      end
    end

    context 'return to main menu' do
      it 'should return' do
        @input.stub!(:gets).with().and_return("return\n")

        subject.run.should be_nil
      end
    end
  end
end

