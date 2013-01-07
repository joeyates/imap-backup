# encoding: utf-8
require 'spec_helper'

describe Imap::Backup::Configuration::ConnectionTester do

  context '.test' do

    it 'should try to connect' do
      Imap::Backup::Account::Connection.should_receive(:new).with('foo')

      Imap::Backup::Configuration::ConnectionTester.test('foo')
    end

    it 'should return success if the connection works' do
      Imap::Backup::Account::Connection.stub!(:new).
                                        with('foo')

      result = Imap::Backup::Configuration::ConnectionTester.test('foo')

      result.should =~ /successful/
    end

    it 'should handle no response' do
      e = Net::IMAP::NoResponseError.new(stub('o', :data => stub('foo', :text => 'bar')))
      Imap::Backup::Account::Connection.stub!(:new).
                                        with('foo').
                                        and_raise(e)

      result = Imap::Backup::Configuration::ConnectionTester.test('foo')

      result.should =~ /no response/i
    end

    it 'should handle other errors' do
      Imap::Backup::Account::Connection.stub!(:new).
                                        with('foo').
                                        and_raise('error')

      result = Imap::Backup::Configuration::ConnectionTester.test('foo')

      result.should =~ /unexpected error/i
    end

  end

end

