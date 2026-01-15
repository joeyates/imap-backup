require "imap/backup/account/folder"
require "imap/backup/account/folder_backup"

module Imap::Backup
  RSpec.describe Account::FolderBackup do
    subject { described_class.new(account: account, folder: folder, refresh: refresh) }

    let(:account) do
      instance_double(
        Account,
        client: client,
        download_strategy: download_strategy,
        local_path: "/backups",
        mirror_mode: mirror_mode,
        multi_fetch_size: 42,
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
    end
    let(:client) { instance_double(Client::Default) }
    let(:folder) do
      instance_double(
        Account::Folder,
        exist?: folder_exists,
        name: "INBOX",
        uid_validity: 123
      )
    end
    let(:folder_exists) { true }
    let(:mirror_mode) { false }
    let(:refresh) { false }
    let(:download_strategy) { "direct" }
    let(:reset_seen_flags_after_fetch) { false }
    let(:raw_serializer) do
      instance_double(
        Serializer,
        apply_uid_validity: nil,
        transaction: nil
      )
    end
    let(:delayed_serializer) do
      instance_double(
        Serializer::DelayedMetadataSerializer,
        apply_uid_validity: nil,
        transaction: nil
      )
    end
    let(:downloader) { instance_double(Downloader, run: nil) }
    let(:flag_refresher) { instance_double(FlagRefresher, run: nil) }
    let(:local_only_message_deleter) do
      instance_double(LocalOnlyMessageDeleter, run: nil)
    end

    before do
      allow(Serializer).to receive(:new) { raw_serializer }
      allow(raw_serializer).to receive(:transaction).and_yield
      allow(Serializer::DelayedMetadataSerializer).
        to receive(:new) { delayed_serializer }
      allow(delayed_serializer).to receive(:transaction).and_yield
      allow(Downloader).to receive(:new) { downloader }
      allow(FlagRefresher).to receive(:new) { flag_refresher }
      allow(LocalOnlyMessageDeleter).
        to receive(:new) { local_only_message_deleter }
      allow(Logger.logger).to receive(:info)
    end

    it "runs the downloader" do
      subject.run

      expect(downloader).to have_received(:run)
    end

    it "passes the multi_fetch_size" do
      subject.run

      expect(Downloader).to have_received(:new).
        with(anything, anything, hash_including(multi_fetch_size: 42))
    end

    context "when the folder does not exist" do
      let(:folder_exists) { false }

      it "logs the problem" do
        subject.run

        expect(Logger.logger).
          to have_received(:info).
          with("Skipping backup for folder 'INBOX' as it does not exist")
      end

      it "does not run the downloader" do
        subject.run

        expect(downloader).to_not have_received(:run)
      end
    end

    context "when the folder name is invalid" do
      before do
        allow(folder).to receive(:exist?).and_raise(Encoding::UndefinedConversionError)
      end

      it "logs the problem" do
        subject.run

        expect(Logger.logger).
          to have_received(:info).
          with("Skipping backup for 'INBOX' as it's name is not UTF-7 encoded correctly")
      end
    end

    context "when using the 'direct' download strategy" do
      it "passes the raw serializer to the downloader" do
        subject.run

        expect(Downloader).to have_received(:new).
          with(folder, raw_serializer, anything)
      end
    end

    context "when using the 'delay metadata' strategy" do
      let(:download_strategy) { "delay_metadata" }

      it "passes the delayed serializer to the downloader" do
        subject.run

        expect(Downloader).to have_received(:new).
          with(folder, delayed_serializer, anything)
      end
    end

    context "when the strategy is unknown" do
      let(:download_strategy) { "other" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(/Unknown download strategy/)
      end
    end

    context "when mirror mode is enabled" do
      let(:mirror_mode) { true }

      it "deletes local-only messages" do
        subject.run

        expect(local_only_message_deleter).
          to have_received(:run)
      end
    end

    context "when refresh is requested" do
      let(:refresh) { true }

      it "refreshes flags even without mirror mode" do
        subject.run

        expect(flag_refresher).to have_received(:run)
      end
    end

    context "when reset_seen_flags_after_fetch is set" do
      let(:reset_seen_flags_after_fetch) { true }

      it "passes reset_seen_flags_after_fetch" do
        subject.run

        expect(Downloader).to have_received(:new).
          with(anything, anything, hash_including(reset_seen_flags_after_fetch: true))
      end
    end
  end
end
