# rubocop:disable RSpec/PredicateMatcher

module Imap::Backup
  describe Account::Folder do
    subject { described_class.new(client, folder_name) }

    let(:client) do
      instance_double(
        Client::Default,
        append: append_response,
        create: nil,
        examine: nil,
        expunge: nil,
        responses: responses,
        select: nil,
        uid_store: nil
      )
    end
    let(:folder_name) { "Gelöscht" }
    let(:encoded_folder_name) { "Gel&APY-scht" }
    let(:missing_mailbox_data) do
      OpenStruct.new(text: "Unknown Mailbox: #{folder_name}")
    end
    let(:missing_mailbox_response) { OpenStruct.new(data: missing_mailbox_data) }
    let(:missing_mailbox_error) do
      Net::IMAP::NoResponseError.new(missing_mailbox_response)
    end
    let(:responses) { [] }
    let(:append_response) { nil }
    let(:uids) { [5678, 123] }
    let(:bad_response_error_response) do
      response_text = Net::IMAP::ResponseText.new(42, "BOOM")
      Net::IMAP::TaggedResponse.new("BAD", "name", response_text, "BOOM")
    end

    before { allow(client).to receive(:uid_search).with(["ALL"]) { uids } }

    describe "#uids" do
      it "lists available messages" do
        expect(subject.uids).to eq(uids.reverse)
      end

      context "with missing mailboxes" do
        before do
          allow(client).to receive(:examine).
            with(encoded_folder_name).and_raise(missing_mailbox_error)
        end

        it "returns an empty array" do
          expect(subject.uids).to eq([])
        end
      end

      context "with no SEARCH response in Net::IMAP" do
        let(:no_method_error) do
          NoMethodError.new("Somethimes SEARCH responses come out undefined")
        end

        before do
          allow(client).to receive(:examine).
            with(encoded_folder_name).and_raise(missing_mailbox_error)
        end

        it "returns an empty array" do
          expect(subject.uids).to eq([])
        end
      end

      context "when the UID search fails" do
        before do
          allow(client).to receive(:uid_search).and_raise(NoMethodError)
        end

        it "returns an empty array" do
          expect(subject.uids).to eq([])
        end
      end
    end

    describe "#fetch_multi" do
      let(:message_body) { instance_double(String, force_encoding: nil) }
      let(:attributes) do
        {"UID" => "uid", "BODY[]" => message_body, "FLAGS" => [:MyFlag], "other" => "xxx"}
      end
      let(:fetch_data_item) do
        instance_double(Net::IMAP::FetchData, attr: attributes)
      end

      before { allow(client).to receive(:uid_fetch) { [fetch_data_item] } }

      it "returns the uid, message and flags" do
        expected = [{uid: "uid", body: message_body, flags: [:MyFlag]}]
        expect(subject.fetch_multi([123])).to eq(expected)
      end

      context "when the server responds with nothing" do
        before { allow(client).to receive(:uid_fetch) { nil } }

        it "is nil" do
          expect(subject.fetch_multi([123])).to be_nil
        end
      end

      context "when the mailbox doesn't exist" do
        before do
          allow(client).to receive(:examine).
            with(encoded_folder_name).and_raise(missing_mailbox_error)
        end

        it "is nil" do
          expect(subject.fetch_multi([123])).to be_nil
        end
      end

      context "when the first fetch_uid attempts fail with EOF" do
        before do
          outcomes = [-> { raise EOFError }, -> { [fetch_data_item] }]
          allow(client).to receive(:uid_fetch) { outcomes.shift.call }
        end

        it "retries" do
          subject.fetch_multi([123])

          expect(client).to have_received(:uid_fetch).twice
        end

        it "succeeds" do
          subject.fetch_multi([123])
        end
      end

      context "when the first fetch_uid attempts fail with Errno::ECONNRESET" do
        before do
          outcomes = [-> { raise Errno::ECONNRESET }, -> { [fetch_data_item] }]
          allow(client).to receive(:uid_fetch) { outcomes.shift.call }
        end

        it "retries" do
          subject.fetch_multi([123])

          expect(client).to have_received(:uid_fetch).twice
        end

        it "succeeds" do
          subject.fetch_multi([123])
        end
      end
    end

    describe "#exist?" do
      context "when the folder exists" do
        it "is true" do
          expect(subject.exist?).to be_truthy
        end
      end

      context "when the folder doesn't exist" do
        before do
          allow(client).to receive(:examine).
            with(encoded_folder_name).and_raise(missing_mailbox_error)
        end

        it "is false" do
          expect(subject.exist?).to be_falsey
        end
      end

      context "when the examine fails with a BadResponseError" do
        before do
          outcomes = [
            -> { raise Net::IMAP::BadResponseError, bad_response_error_response },
            -> {}
          ]
          allow(client).to receive(:examine) { outcomes.shift.call }
        end

        it "retries" do
          subject.create

          expect(client).to have_received(:examine).twice
        end
      end
    end

    describe "#create" do
      context "when the folder exists" do
        it "is does not create the folder" do
          expect(client).to_not receive(:create)

          subject.create
        end
      end

      context "when the folder doesn't exist" do
        before do
          allow(client).to receive(:examine).
            with(encoded_folder_name).and_raise(missing_mailbox_error)
        end

        it "creates the folder" do
          expect(client).to receive(:create)

          subject.create
        end

        it "encodes the folder name" do
          expect(client).to receive(:create).with(encoded_folder_name)

          subject.create
        end

        context "when the create fails with a BadResponseError" do
          before do
            outcomes = [
              -> { raise Net::IMAP::BadResponseError, bad_response_error_response },
              -> {}
            ]
            allow(client).to receive(:create) { outcomes.shift.call }
          end

          it "retries" do
            subject.create

            expect(client).to have_received(:create).twice
          end
        end
      end
    end

    describe "#uid_validity" do
      let(:responses) { {"UIDVALIDITY" => ["x", "uid validity"]} }

      it "is returned" do
        expect(subject.uid_validity).to eq("uid validity")
      end

      context "when the folder doesn't exist" do
        before do
          allow(client).to receive(:examine).
            with(encoded_folder_name).and_raise(missing_mailbox_error)
        end

        it "raises an error" do
          expect do
            subject.uid_validity
          end.to raise_error(FolderNotFound)
        end
      end
    end

    describe "#append" do
      let(:message) do
        instance_double(
          Serializer::Message,
          imap_body: "imap body",
          date: message_date,
          flags: %i(Draft MyFlag)
        )
      end
      let(:message_date) { Time.new(2010, 10, 10, 9, 15, 22, 0) }
      let(:append_response) do
        uid_data = instance_double(
          Net::IMAP::UIDPlusData, uidvalidity: 1, assigned_uids: [2]
        )
        OpenStruct.new(data: OpenStruct.new(code: OpenStruct.new(data: uid_data)))
      end

      it "appends the message" do
        expect(client).to receive(:append)

        subject.append(message)
      end

      it "sets the body" do
        expect(client).to receive(:append).
          with(anything, "imap body", anything, anything)

        subject.append(message)
      end

      it "sets permitted flags" do
        expect(client).to receive(:append).
          with(anything, anything, [:Draft], anything)

        subject.append(message)
      end

      it "sets the date and time" do
        expect(client).to receive(:append).
          with(anything, anything, anything, message_date)

        subject.append(message)
      end

      it "returns the new uid" do
        expect(subject.append(message)).to eq(2)
      end

      it "sets the new uid validity" do
        subject.append(message)

        expect(subject.uid_validity).to eq(1)
      end

      context "when the append fails with a BadResponseError" do
        before do
          outcomes = [
            -> { raise Net::IMAP::BadResponseError, bad_response_error_response },
            -> { append_response }
          ]
          allow(client).to receive(:append) { outcomes.shift.call }
        end

        it "retries" do
          subject.append(message)

          expect(client).to have_received(:append).twice
        end
      end
    end

    describe "#set_flags" do
      before { subject.set_flags([99], [:Foo]) }

      it "uses select to have read-write access" do
        expect(client).to have_received(:select)
      end

      it "sets the flag" do
        expect(client).
          to have_received(:uid_store).with([99], "FLAGS", [:Foo])
      end
    end

    describe "#add_flags" do
      before { subject.add_flags([99], [:Foo]) }

      it "uses select to have read-write access" do
        expect(client).to have_received(:select)
      end

      it "sets the flag" do
        expect(client).
          to have_received(:uid_store).with([99], "+FLAGS", [:Foo])
      end
    end

    describe "#remove_flags" do
      before { subject.remove_flags([99], [:Foo]) }

      it "uses select to have read-write access" do
        expect(client).to have_received(:select)
      end

      it "unsets the flag" do
        expect(client).
          to have_received(:uid_store).with([99], "-FLAGS", [:Foo])
      end
    end

    describe "#clear" do
      before { subject.clear }

      it "uses select to have read-write access" do
        expect(client).to have_received(:select)
      end

      it "marks all emails as deleted" do
        expect(client).
          to have_received(:uid_store).with(uids.sort, "+FLAGS", [:Deleted])
      end

      it "deletes marked emails" do
        expect(client).to have_received(:expunge)
      end
    end

    describe "#unseen" do
      let(:result) { subject.unseen([42, 99]) }

      before do
        allow(client).to receive(:uid_search).with(["42,99", "UNSEEN"]) { [42] }
      end

      it "returns UIDs of unseen messages" do
        expect(result).to eq([42])
      end

      context "when the unseen search fails" do
        before do
          allow(client).to receive(:uid_search).with([anything, "UNSEEN"]).and_raise(NoMethodError)
        end

        it "returns an empty array" do
          expect(result).to eq([])
        end
      end

      context "when the folder doesn't exist" do
        before do
          allow(client).to receive(:uid_search).with([anything, "UNSEEN"]).and_raise(FolderNotFound)
        end

        it "returns an empty array" do
          expect(result).to be nil
        end
      end
    end
  end
end

# rubocop:enable RSpec/PredicateMatcher
