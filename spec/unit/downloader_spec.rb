# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Imap::Backup::Downloader do

  context 'with account and downloader' do

    before :each do
      local_path = '/base/path'
      stat       = stub('File::Stat', :mode => 0700)
      File.stub!(:stat).with(local_path).and_return(stat)

      @message = {
        'RFC822' => 'the body',
        'other'  => 'xxx'
      }
      @folder     = stub('Imap::Backup::Account::Folder', :fetch => @message)
      @serializer = stub('Imap::Backup::Serializer', :prepare => nil,
                                                     :exist?  => true,
                                                     :uids    => [],
                                                     :save    => nil)
    end

    subject { Imap::Backup::Downloader.new(@folder, @serializer) }

    context '#run' do

      context 'with folder' do

        it 'should list messages' do
          @folder.should_receive(:uids).and_return([])

          subject.run
        end

        context 'with messages' do
          before :each do
            @folder.stub!(:uids).and_return(['123', '999', '1234'])
          end

          it 'should skip messages that are downloaded' do
            File.stub!(:exist?).and_return(true)

            @serializer.should_not_receive(:fetch)

            subject.run
          end

          context 'to download' do
            before :each do
              @serializer.stub!(:exist?) do |uid|
                if uid == '123'
                  true
                else
                  false
                end
              end
            end

            it 'should request messages' do
              @folder.should_receive(:fetch).with('999')
              @folder.should_receive(:fetch).with('1234')

              subject.run
            end

            it 'should save messages' do
              @serializer.should_receive(:save).with('999', @message)
              @serializer.should_receive(:save).with('1234', @message)

              subject.run
            end

          end

        end

      end

    end

  end

end

