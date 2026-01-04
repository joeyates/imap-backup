require "imap/backup/mirror"

require "imap/backup/client/default"
require "imap/backup/serializer"
require "imap/backup/account/folder"

module Imap::Backup
  RSpec.describe Mirror do
    subject { described_class.new(serializer, folder, reset: reset) }

    let(:serializer) do
      instance_double(
        Serializer,
        folder_path: "/tmp/source",
        uid_validity: 10,
        uids: source_uids,
        get: serializer_message
      )
    end
    let(:folder) do
      instance_double(
        Account::Folder,
        exist?: destination_exists,
        create: nil,
        delete_multi: nil,
        uids: destination_uids,
        fetch_multi: fetched_flags,
        set_flags: nil,
        append: appended_uid,
        uid_validity: 20,
        clear: nil,
        client: client
      )
    end
    let(:client) { instance_double(Client::Default, username: "dest@example.com") }
    let(:map) do
      instance_double(
        Mirror::Map,
        reset: nil,
        save: nil,
        destination_uid: nil,
        map_uids: nil
      )
    end
    let(:serializer_message) do
      instance_double(Serializer::Message, uid: 1, flags: serializer_flags)
    end
    let(:serializer_flags) { [:Seen] }
    let(:destination_exists) { true }
    let(:destination_uids) { [] }
    let(:fetched_flags) { [] }
    let(:appended_uid) { 123 }
    let(:source_uids) { [] }
    let(:uid_validities_ok) { true }
    let(:reset) { false }

    before do
      allow(Mirror::Map).to receive(:new) { map }
      allow(map).to receive(:check_uid_validities) { uid_validities_ok }
      allow(serializer).to receive(:each_message).and_yield(serializer_message)
    end

    describe "#run" do
      context "when the destination folder does not exist" do
        let(:destination_exists) { false }

        it "creates the folder" do
          subject.run

          expect(folder).to have_received(:create)
        end
      end

      context "when reset is false" do
        context "when uid validities do not match" do
          let(:uid_validities_ok) { false }

          it "does not clear the folder" do
            subject.run

            expect(folder).not_to have_received(:clear)
          end
        end

        context "when uid validities match" do
          it "does not clear the folder" do
            subject.run

            expect(folder).not_to have_received(:clear)
          end
        end
      end

      context "when reset is true" do
        let(:reset) { true }
        let(:source_uids) { [1] }
        let(:destination_uids) { [201] }
        let(:fetched_flags) { [{uid: 201, flags: [:Seen]}] }

        before do
          allow(map).to receive(:source_uid).with(201) { 1 }
          allow(map).to receive(:map_uids)
          allow(folder).to receive(:append) { 202 }
        end

        it "deletes destination-only emails" do
          allow(serializer).to receive(:uids) { [1] }
          allow(folder).to receive(:uids) { [201, 202] }
          allow(map).to receive(:source_uid).with(201) { nil }
          allow(map).to receive(:source_uid).with(202) { 1 }

          subject.run

          expect(folder).to have_received(:delete_multi).with([201])
        end

        context "when uid validities do not match" do
          let(:uid_validities_ok) { false }

          it "clears the folder" do
            subject.run

            expect(folder).to have_received(:clear)
          end
        end

        context "when uid validities match" do
          it "does not clear the folder" do
            subject.run

            expect(folder).not_to have_received(:clear)
          end
        end
      end

      context "when flags differ" do
        let(:destination_uids) { [201] }
        let(:fetched_flags) { [{uid: 201, flags: [:Answered]}] }

        before do
          allow(serializer).to receive(:get).with(101) { serializer_message }
          allow(map).to receive(:source_uid).with(201) { 101 }
        end

        it "updates destination flags" do
          subject.run

          expect(folder).to have_received(:set_flags).with([201], [:Seen])
        end
      end

      context "with existing messages" do
        let(:source_uids) { [1] }
        let(:destination_uids) { [201] }

        it "does not append existing messages" do
          allow(map).to receive(:destination_uid).with(1) { 201 }

          subject.run

          expect(folder).not_to have_received(:append)
        end
      end

      context "when appending new messages" do
        let(:serializer_flags) { [:Seen] }
        let(:source_uids) { [1] }

        it "maps appended UIDs" do
          subject.run

          expect(map).to have_received(:map_uids).with(source: 1, destination: appended_uid)
        end

        it "removes the :Recent flag before appending" do
          subject.run

          expect(folder).to have_received(:append) do |message|
            expect(message.flags).to eq([:Seen])
          end
        end
      end
    end
  end
end
