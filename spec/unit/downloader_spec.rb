# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Downloader do

  context '#initialize' do

    it 'should fail if download path file permissions are to lax' do
      account = stub('Imap::Backup::Account', :local_path => 'foobar')
      stat = stub('File::Stat', :mode => 0345)
      File.should_receive(:stat).with('foobar').and_return(stat)

      expect do
        Imap::Backup::Downloader.new(account, 'foo')
      end.to raise_error(RuntimeError, "Permissions on 'foobar' should be 0700, not 0345")
    end

  end

  context 'with account and downloader' do

    before :each do
      local_path = '/base/path'
      stat       = stub('File::Stat', :mode => 0700)
      File.stub!(:stat).with(local_path).and_return(stat)

      @account = stub('Imap::Backup::Account', :local_path => local_path)
      @d       = Imap::Backup::Downloader.new(@account, 'my_folder')
    end

    context '#status' do

      context 'local' do

        before :each do
          @account.stub!(:uids).and_return([])
        end

        it 'should return the backed-up uids' do
          files = ['00000123.json']

          File.should_receive(:exist?).with('/base/path/my_folder').and_return(true)
          Dir.should_receive(:open).with('/base/path/my_folder').and_return(files)

          status = @d.status

          status[:local].should == ['123']
        end

        it 'should return an empty Array of there is are local copies' do
          File.should_receive(:exist?).with('/base/path/my_folder').and_return(false)

          status = @d.status

          status[:local].should == []
        end
      end

      context 'remote' do

        it 'should retrieve the available uids' do
          File.stub!(:exist?).and_return(false)

          @account.should_receive(:uids).with('my_folder').and_return(['234'])

          status = @d.status

          status[:remote].should == ['234']
        end

      end

    end

    context '#run' do

      it 'should create the folder and update permissions' do
        @account.stub!(:each_uid)
        FileUtils.should_receive(:mkdir_p).with('/base/path/my_folder')
        FileUtils.should_receive(:chmod_R).with('g-wrx,o-wrx', '/base/path/my_folder')

        @d.run
      end

      context 'with folder' do
        before :each do
          FileUtils.stub!(:mkdir_p)
          FileUtils.stub!(:chmod_R)
        end

        it 'should list messages' do
          @account.should_receive(:each_uid)

          @d.run
        end

        context 'with messages' do
          before :each do
            @account.should_receive(:each_uid) do |&block|
            block.call '123'
            block.call '999'
            block.call '1234'
            end
          end

          it 'should check if messages exist' do
            File.should_receive(:exist?).with(%r{/base/path/my_folder/\d+.json}).exactly(3).times.and_return(true)

            @d.run
          end

          it 'should skip messages that are downloaded' do
            File.stub!(:exist?).and_return(true)

            @account.should_not_receive(:fetch)

            @d.run
          end

          context 'to download' do
            before :each do
              # N.B. messages 999 and 1234 wil be 'fetched'
              File.stub!(:exist?) do |path|
                if path =~ %r{123.json$}
                  true
                else
                  false
                end
              end

              @message = {
                'RFC822' => 'the body',
                'other'  => 'xxx'
              }
              @account.stub!(:fetch => @message)
              File.stub!(:open)
              FileUtils.stub!(:chmod)
            end

            it 'should request messages' do
              @account.should_receive(:fetch).with('999')
              @account.should_receive(:fetch).with('1234')

              @d.run
            end

            it 'should save messages' do
              file = stub('File')
              File.should_receive(:open) do |&block|
              block.call file
              end
              file.should_receive(:write).with(/the body/)

              @d.run
            end

            it 'should JSON encode messages' do
              file = stub('File', :write => nil)
              File.stub!(:open) do |&block|
              block.call file
              end

              @message.should_receive(:to_json).twice

              @d.run
            end

            it 'should set file permissions' do
              FileUtils.should_receive(:chmod).with(0600, /999.json$/)
              FileUtils.should_receive(:chmod).with(0600, /1234.json$/)

              @d.run
            end

          end
        end

      end
  end

  end

end

