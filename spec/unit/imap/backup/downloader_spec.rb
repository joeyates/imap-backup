describe Imap::Backup::Downloader do
  describe "#run" do
    subject { described_class.new(folder, serializer, **options) }

    let(:body) { "blah" }
    let(:folder) do
      instance_double(
        Imap::Backup::Account::Folder,
        fetch_multi: [{uid: "111", body: body}],
        name: "folder",
        uids: remote_uids
      )
    end
    let(:remote_uids) { %w(111 222 333) }
    let(:serializer) do
      instance_double(Imap::Backup::Serializer, append: nil, uids: local_uids)
    end
    let(:local_uids) { ["222"] }
    let(:options) { {} }

    context "with fetched messages" do
      specify "are saved" do
        expect(serializer).to receive(:append).with("111", body)

        subject.run
      end
    end

    context "with messages which are already present" do
      specify "are skipped" do
        expect(serializer).to_not receive(:append).with("222", anything)

        subject.run
      end
    end

    context "with failed fetches" do
      specify "are skipped" do
        allow(folder).to receive(:fetch_multi) { nil }
        expect(serializer).to_not receive(:append)

        subject.run
      end
    end

    context "when the block size is greater than one" do
      let(:remote_uids) { %w(111 999) }
      let(:local_uids) { [] }
      let(:options) { {multi_fetch_size: 2} }

      context "when the first fetch fails" do
        before do
          allow(folder).to receive(:fetch_multi).with(%w[111 999]) { nil }
          allow(folder).to receive(:fetch_multi).with(["111"]).
            and_return([{uid: "111", body: body}]).
            and_return([{uid: "999", body: body}])

          subject.run
        end

        it "retries fetching messages singly" do
          expect(serializer).to have_received(:append).with("111", body)
          expect(serializer).to have_received(:append).with("999", body)
        end
      end
    end

    context "when no body is returned by the fetch" do
      let(:remote_uids) { %w(111) }

      before do
        allow(folder).to receive(:fetch_multi).with(["111"]) { [{uid: "111", body: nil}] }

        subject.run
      end

      it "skips the append" do
        expect(serializer).to_not have_received(:append)
      end
    end

    context "when the UID is not returned by the fetch" do
      let(:remote_uids) { %w(111) }

      before do
        allow(folder).to receive(:fetch_multi).with(["111"]) { [{uid: nil, body: body}] }

        subject.run
      end

      it "skips the append" do
        expect(serializer).to_not have_received(:append)
      end
    end
  end
end
