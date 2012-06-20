# encoding: utf-8
load File.expand_path( '../../spec_helper.rb', File.dirname(__FILE__) )

module HighLineTestHelpers

  def prepare_highline
    @input  = stub('stdin', :eof? => false)
    # default gets stub
    @input.stub!(:gets).with().and_return("q\n")
    @output = StringIO.new
    Imap::Backup::Configuration::Setup.highline = HighLine.new(@input, @output)
    [@input, @output]
  end

end

module InputOutputTestHelpers

  def capturing_output
    output = StringIO.new
    $stdout = output
    yield
    output.string
  ensure
    $stdout = STDOUT
  end

end

describe Imap::Backup::Configuration::Setup do

  include HighLineTestHelpers

  context '#initialize' do

    it 'should not require the config file to exist' do
      Imap::Backup::Configuration::Store.should_receive(:new).with(false)

      Imap::Backup::Configuration::Setup.new
    end

  end

  context '#run' do

    before :each do
      prepare_store
      @input, @output = prepare_highline
    end

    def prepare_store
      accounts = [
        { :username => 'account@example.com' }
      ]
      @data  = {:accounts => accounts}
      @store = stub('Imap::Backup::Configuration::Store', :data => @data, :path => '/base/path')
      Imap::Backup::Configuration::Store.stub!(:new).with(false).and_return(@store)
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
      Imap::Backup::Configuration::Account.should_receive(:new).with(@store, 'account@example.com').and_return(@account)
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

      Imap::Backup::Configuration::Asker.should_receive(:email).with().and_return('new@example.com')
      Imap::Backup::Configuration::Account.should_receive(:new).with(@store, 'new@example.com')

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

describe Imap::Backup::Configuration::FolderChooser do

  include HighLineTestHelpers
  include InputOutputTestHelpers

  context '#run' do

    before :each do
      empty_account = {
        :folders => []
      }
      @connection = setup_account(empty_account, [])
      @input, @output = prepare_highline
    end

    def setup_account(account, remote_folders)
      @account   = account
      connection = stub('Imap::Backup::Account::Connection')
      connection.stub!(:folders).and_return(remote_folders)
      Imap::Backup::Account::Connection.stub!(:new).with(account).and_return(connection)
      connection
    end

    subject { Imap::Backup::Configuration::FolderChooser.new(@account) }

    it 'should connect to the account' do
      Imap::Backup::Account::Connection.should_receive(:new).with(@account).and_return(@connection)

      subject.run
    end

    it 'should handle connection errors' do
      Imap::Backup::Account::Connection.should_receive(:new).with(@account).and_raise('error')
      Imap::Backup::Configuration::Setup.highline.should_receive(:ask).with('Press a key ')

      capturing_output do
        subject.run
      end.should =~ /connection failed/i
    end

    it 'should get a list of account folders' do
      @connection.should_receive(:folders).and_return([])

      subject.run
    end

    it 'should show the menu' do
      subject.run
      
      @output.string.should =~ %r{Add/remove folders}
    end

    it 'should return to the account menu' do
      @input.should_receive(:gets).and_return("return\n")

      subject.run
      
      @output.string.should =~ %r{return to the account menu}
    end

    context 'folder listing' do

      before :each do
        account = {
          :folders => [{:name => 'my_folder'}]
        }
        folder1 = stub('folder', :name => 'my_folder')       # this one is already backed up
        folder2 = stub('folder', :name => 'another_folder')
        remote_folders = [folder1, folder2]
        @connection = setup_account(account, remote_folders)
      end

      it 'should list folders' do
        subject.run
 
        @output.string.should =~ /my_folder/
      end

      it 'should show which folders are already being backed up' do
        subject.run
 
        @output.string.should =~ /\d+\. \+ my_folder/
        @output.string.should =~ /\d+\. \- another_folder/
      end

      it 'should add folders' do
        state = :initial
        @input.stub(:gets) do
          case state
          when :initial
            state = :added
            "2\n"         # choose 'another_folder'
          else
            "q\n"
          end
        end

        subject.run

        @output.string.should =~ /\d+\. \+ another_folder/
        @account[:folders].should include( { :name => 'another_folder' } )
      end

      it 'should remove folders' do
        state = :initial
        @input.stub(:gets) do
          case state
          when :initial
            state = :added
            "1\n"
          else
            "q\n"
          end
        end

        subject.run

        @output.string.should =~ /\d+\. \- my_folder/
        @account[:folders].should_not include( { :name => 'my_folder' } )
      end


    end

  end

end

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

