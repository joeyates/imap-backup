module Imap::Backup
  RSpec.describe Account::FolderEnsurer do
    subject { described_class.new(account: account) }

    let(:account) { instance_double(Account, local_path: local_path, username: "username") }
    let(:local_path) { "local_path" }

    context "when local_path is not set" do
      let(:local_path) { nil }

      it "fails" do
        expect { subject.run }.to raise_error(RuntimeError, /backup path.*?not set/)
      end
    end

    context "when the directory does not exist" do
      before { allow(Utils).to receive(:make_folder) }

      it "creates it" do
        subject.run

        expect(Utils).to have_received(:make_folder)
      end
    end
  end
end
