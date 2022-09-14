module Imap::Backup
  describe CLI::Mirror do
    subject { described_class.new(source, destination, **options) }

    let(:source) { "source" }
    let(:destination) { "destination" }
    let(:options) { {} }
    let(:mirror) { instance_double(Mirror, run: nil) }
    let(:config) { instance_double(Configuration, accounts: [account1, account2]) }
    let(:account1) { instance_double(Account, username: source, connection: connection1, local_path: "path") }
    let(:connection1) { instance_double(Account::Connection, run_backup: nil) }
    let(:account2) { instance_double(Account, username: destination, connection: connection2) }
    let(:connection2) { instance_double(Account::Connection) }
    let(:pathname) { Pathname.new("path/folder.imap") }

    before do
      allow(Configuration).to receive(:new) { config }
      allow(Mirror).to receive(:new) { mirror }
      allow(Pathname).to receive(:glob).and_yield(pathname)

      subject.run
    end

    it "runs backup on the source" do
      expect(connection1).to have_received(:run_backup)
    end

    it "mirrors each folder" do
      expect(mirror).to have_received(:run)
    end
  end
end
