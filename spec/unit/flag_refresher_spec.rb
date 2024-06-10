require "imap/backup/account/folder"
require "imap/backup/flag_refresher"
require "imap/backup/serializer"

module Imap::Backup
  RSpec.describe FlagRefresher do
    subject { described_class.new(folder, serializer) }

    let(:serializer) { instance_double(Serializer, uids: [1, 2]) }
    let(:folder) { instance_double(Account::Folder, uids: [2], name: "my_folder") }

    it "refreshes the flags" do
      response = [{uid: 1, flags: [:Draft]}, {uid: 2, flags: [:Seen]}]
      allow(folder).to receive(:fetch_multi).with([1, 2], ["FLAGS"]) { response }

      expect(serializer).to receive(:update).with(1, flags: [:Draft])
      expect(serializer).to receive(:update).with(2, flags: [:Seen])

      subject.run
    end

    context "when the fetch fails" do
      it "logs a warning" do
        allow(folder).to receive(:fetch_multi).with([1, 2], ["FLAGS"]).and_return(nil)
        expect(Logger.logger).
          to receive(:debug).
          with("[#{folder.name}] failed to fetch flags for [1, 2] - cannot refresh flags")

        subject.run
      end
    end
  end
end
