require "imap/backup/cli/folder_enumerator"

module Imap::Backup
  describe CLI::FolderEnumerator do
    subject { described_class.new(**options) }

    let(:path) { "folder_enumerator_path/foo.imap" }
    let(:imap_pathname) { Pathname.new(path) }
    let(:options) { {source: source, destination: destination} }
    let(:source) do
      instance_double(Account, username: "source", local_path: "folder_enumerator_path")
    end
    let(:destination) { instance_double(Account, username: "destination", client: client) }
    let(:client) { instance_double(Client::Default) }
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

    context "without provided values" do
      let(:path) { "folder_enumerator_path/foo/bar.imap" }

      specify "delimiters default to '/'" do
        expect(result[1].name).to eq("foo/bar")
      end
    end

    context "when destination_delimiter is supplied" do
      let(:options) { super().merge(destination_delimiter: ".") }
      let(:path) { "folder_enumerator_path/bar/foo.imap" }

      it "removes the prefix" do
        expect(result[1].name).to eq("bar.foo")
      end
    end

    context "when destination_prefix is supplied" do
      let(:options) { super().merge(destination_prefix: "dest") }
      let(:path) { "folder_enumerator_path/foo.imap" }

      it "removes the prefix" do
        expect(result[1].name).to eq("dest/foo")
      end
    end

    context "when the destination_prefix ends with the delimiter" do
      let(:options) { super().merge(destination_delimiter: ":", destination_prefix: "dest:") }
      let(:path) { "folder_enumerator_path/foo.imap" }

      it "removes the delimiter" do
        expect(result[1].name).to eq("dest:foo")
      end
    end

    context "when source_delimiter is supplied" do
      let(:options) { super().merge(source_delimiter: ".") }
      let(:path) { "folder_enumerator_path/src.foo.imap" }

      it "handle the delimiter" do
        expect(result[1].name).to eq("src/foo")
      end
    end

    context "when source_prefix is supplied" do
      let(:options) { super().merge(source_prefix: "src") }
      let(:path) { "folder_enumerator_path/src/foo.imap" }

      it "removes the prefix" do
        expect(result[1].name).to eq("foo")
      end
    end

    context "when the source_prefix ends with the delimiter" do
      let(:options) { super().merge(source_delimiter: ":", source_prefix: "src:") }
      let(:path) { "folder_enumerator_path/src:foo.imap" }

      it "removes the delimiter" do
        expect(result[1].name).to eq("foo")
      end
    end
  end
end
