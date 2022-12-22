module Imap::Backup
  describe CLI::Mirror do
    subject { described_class.new(source, destination, **options) }

    let(:source) { "source" }
    let(:destination) { "destination" }
    let(:options) { {} }
    let(:mirror) { instance_double(Mirror, run: nil) }
    let(:config) { instance_double(Configuration, accounts: [account1, account2]) }
    let(:account1) do
      instance_double(
        Account,
        username: source, connection: connection1, local_path: "path", mirror_mode: false
      )
    end
    let(:connection1) { instance_double(Account::Connection, "connection1", run_backup: nil) }
    let(:account2) { instance_double(Account, username: destination, connection: connection2) }
    let(:connection2) { instance_double(Account::Connection, "connection2") }
    let(:serializer) { instance_double(Serializer) }
    let(:folder) { instance_double(Account::Folder) }
    let(:folder_enumerator) { instance_double(CLI::FolderEnumerator) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Mirror).to receive(:new) { mirror }
      allow(CLI::FolderEnumerator).to receive(:new) { folder_enumerator }
      allow(folder_enumerator).to receive(:each).and_yield(serializer, folder)

      subject.run
    end

    it "runs backup on the source" do
      expect(connection1).to have_received(:run_backup)
    end

    it "mirrors each folder" do
      expect(mirror).to have_received(:run)
    end

    %i[
      destination_delimiter
      destination_email
      destination_prefix
      config_path
      source_delimiter
      source_email
      source_prefix
    ].each do |option|
      it "accepts a #{option} option" do
        opts = options.merge(option => "foo")
        described_class.new(source, destination, **opts)
      end
    end
  end
end
