module Imap::Backup
  describe CLI::Folders do
    subject { described_class.new({}) }

    let(:connection) do
      instance_double(
        Account::Connection, account: account, folder_names: folder_names
      )
    end
    let(:account) { instance_double(Account, username: "user") }
    let(:folder_names) { ["my-folder"] }
    let(:config) { instance_double(Configuration, accounts: [account]) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Kernel).to receive(:puts)
      allow(Kernel).to receive(:warn)
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:each_connection).with(anything, []).and_yield(connection)
      # rubocop:enable RSpec/SubjectStub

      subject.run
    end

    it "lists folders" do
      expect(Kernel).to have_received(:puts).with("\tmy-folder")
    end

    context "when the folder list is not fetched" do
      let(:folder_names) { nil }

      it "warns" do
        expect(Kernel).to have_received(:warn).with(/Unable to list/)
      end

      it "doesn't fail" do
        subject.run
      end
    end
  end
end
