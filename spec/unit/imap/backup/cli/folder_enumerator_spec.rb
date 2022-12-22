require "imap/backup/cli/folder_enumerator"

module Imap::Backup
  describe CLI::FolderEnumerator do
    subject { described_class.new(**options) }

    let(:imap_pathname) { Pathname.new("path/foo.imap") }
    let(:options) { {source: source, destination: destination} }
    let(:source) { instance_double(Account, username: "source", local_path: "path") }
    let(:destination) { instance_double(Account, username: "destination", connection: connection) }
    let(:connection) { instance_double(Account::Connection) }
    let(:result) { subject.each.first }

    before do
      allow(Pathname).to receive(:glob).and_yield(imap_pathname)
      allow(Account::Folder).to receive(:new).and_call_original
    end

    it "returns source folders" do
      expect(result.first.folder).to eq("foo")
    end

    it "returns destination folders" do
      expect(result[1].name).to eq("foo")
    end

    context "when destination_delimiter is supplied" do
      let(:options) { super().merge(destination_delimiter: ".") }
      let(:imap_pathname) { Pathname.new("path/bar/foo.imap") }

      it "removes the prefix" do
        expect(result[1].name).to eq("bar.foo")
      end
    end

    context "when destination_prefix is supplied" do
      let(:options) { super().merge(destination_prefix: "dest") }
      let(:imap_pathname) { Pathname.new("path/foo.imap") }

      it "removes the prefix" do
        expect(result[1].name).to eq("dest/foo")
      end
    end

    context "when source_delimiter is supplied" do
      let(:options) { super().merge(source_delimiter: ".") }
      let(:imap_pathname) { Pathname.new("path/src.foo.imap") }

      it "handle the delimiter" do
        expect(result[1].name).to eq("src/foo")
      end
    end

    context "when source_prefix is supplied" do
      let(:options) { super().merge(source_prefix: "src") }
      let(:imap_pathname) { Pathname.new("path/src/foo.imap") }

      it "removes the prefix" do
        expect(result[1].name).to eq("foo")
      end
    end
  end
end
