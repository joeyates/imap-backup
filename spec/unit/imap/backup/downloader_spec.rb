module Imap::Backup
  RSpec.describe Downloader do
    describe "#run" do
      subject { described_class.new(folder, serializer, **options) }

      let(:body) { "blah" }
      let(:folder) do
        instance_double(
          Account::Folder,
          client: client,
          name: "folder",
          uids: remote_uids
        )
      end
      let(:client) do
        instance_double(
          Client::Default, authenticate: nil, login: nil, reconnect: nil
        )
      end
      let(:remote_uids) { %w(111) }
      let(:serializer) do
        instance_double(Serializer, append: nil, uids: local_uids)
      end
      let(:local_uids) { ["222"] }
      let(:options) { {} }

      context "with fetched messages" do
        specify "are saved" do
          allow(folder).to receive(:fetch_multi).with(["111"]) do
            [{uid: "111", body: body, flags: [:MyFlag]}]
          end

          expect(serializer).to receive(:append).with("111", body, [:MyFlag])

          subject.run
        end
      end

      context "with messages which are already present" do
        specify "are skipped" do
          allow(folder).to receive(:fetch_multi).with(["111"]) do
            [{uid: "111", body: body, flags: [:MyFlag]}]
          end

          expect(serializer).to_not receive(:append).with("222", anything, anything)

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
            allow(folder).to receive(:fetch_multi).with(remote_uids) { nil }
            allow(folder).to receive(:fetch_multi).with(["111"]).
              and_return([{uid: "111", body: body, flags: [:Flag1]}])
            allow(folder).to receive(:fetch_multi).with(["999"]).
              and_return([{uid: "999", body: body, flags: [:Flag2]}])

            subject.run
          end

          it "retries fetching messages singly" do
            expect(serializer).to have_received(:append).with("111", body, [:Flag1])
            expect(serializer).to have_received(:append).with("999", body, [:Flag2])
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

      context "with reset_seen_flags_after_fetch" do
        let(:options) { {reset_seen_flags_after_fetch: true} }

        before do
          allow(folder).to receive(:fetch_multi).with(["111"]) { [{uid: "111", body: body}] }
          allow(folder).to receive(:unseen).and_return([33], [])
          allow(folder).to receive(:remove_flags)

          subject.run
        end

        it "resets seen flags set during fetch" do
          expect(folder).to have_received(:remove_flags).with([33], [:Seen])
        end
      end

      context "when the IMAP session expires" do
        before do
          data = OpenStruct.new(data: "Session expired")
          response = OpenStruct.new(data: data)
          outcomes = [
            -> { raise Net::IMAP::ByeResponseError, response },
            -> { [{uid: "111", body: body}] }
          ]
          allow(folder).to receive(:fetch_multi) { outcomes.shift.call }
        end

        it "reconnects" do
          expect(serializer).to receive(:append)

          subject.run
        end
      end
    end
  end
end
