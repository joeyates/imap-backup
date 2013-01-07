# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::Asker do

  context '.email' do

    it 'should ask for an email' do
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with(/email/)

      Imap::Backup::Configuration::Asker.email
    end

    it 'should validate the address' do
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with(/email/) do |&block|
        q = stub('HighLine::Question', :default=  => nil,
                                       :readline= => nil,
                                       :responses => {})
        q.should_receive(:validate=).with(instance_of(Regexp))

        block.call q
      end

      Imap::Backup::Configuration::Asker.email
    end

    it 'should return the address' do
      Imap::Backup::Configuration::Setup.highline.stub!(:ask).with(/email/).and_return('new@example.com')

      Imap::Backup::Configuration::Asker.email.should == 'new@example.com'
    end

  end

  context '.password' do

    before :each do
      Imap::Backup::Configuration::Setup.highline.stub!(:ask).with(/^password/).and_return('secret')
      Imap::Backup::Configuration::Setup.highline.stub!(:ask).with(/^repeat password/).and_return('secret')
    end

    it 'should ask for a password and confirmation' do
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with(/^password/).and_return('secret')
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with(/^repeat password/).and_return('secret')

      Imap::Backup::Configuration::Asker.password
    end

    it 'should return the password' do
      Imap::Backup::Configuration::Asker.password.should == 'secret'
    end

    it "should ask again if the passwords don't match" do
      state = :password1
      Imap::Backup::Configuration::Setup.highline.stub!(:ask) do
        case state
        when :password1
          state = :confirmation1
          'secret'
        when :confirmation1
          state = :retry?
          'wrong!!!'
        when :retry?
          state = :password2
          'y'
        when :password2
          state = :confirmation2
          'secret'
        when :confirmation2
          'secret'
        end
      end

      Imap::Backup::Configuration::Asker.password
    end

    it 'should return nil if the user cancels' do
      state = :password1
      Imap::Backup::Configuration::Setup.highline.stub!(:ask) do
        case state
        when :password1
          state = :confirmation1
          'secret'
        when :confirmation1
          state = :retry?
          'wrong!!!'
        when :retry?
          state = :password2
          'n'
        end
      end

      Imap::Backup::Configuration::Asker.password.should be_nil
    end

  end

  context '.backup_path' do

    it 'should ask for a directory' do
      validator = /validator/
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with(/directory/) do |&block|
        q = stub('HighLine::Question', :responses => {}, :readline= => nil)
        q.should_receive(:default=).with('default path')
        q.should_receive(:validate=).with(validator)

        block.call q
      end

      Imap::Backup::Configuration::Asker.backup_path('default path', validator)
    end

    it 'should return the choice' do
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with(/directory/).and_return('/path')

      Imap::Backup::Configuration::Asker.backup_path('default path', //).should == '/path'
    end

  end

end

