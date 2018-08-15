require "spec_helper"

describe Imap::Backup::Serializer::Base do
  context "#initialize" do
    let(:stat) { double("File::Stat", mode: 0345) }

    before do
      allow(File).to receive(:exist?).with("/base/path").and_return(true)
      allow(File).to receive(:stat).with("/base/path").and_return(stat)
    end

    it "should fail if file permissions are to lax" do
      message = "Permissions on '/base/path' should be 0700, not 0345"
      expect do
        described_class.new("/base/path", "my_folder")
      end.to raise_error(RuntimeError, message)
    end
  end
end
