module Imap::Backup
  RSpec.describe Setup::Helpers do
    describe "#title_prefix" do
      it "is a string" do
        expect(subject.title_prefix).to eq("imap-backup -")
      end
    end

    describe "#version" do
      it "is a version string" do
        expect(subject.version).to match(/\A\d+\.\d+\.\d+(\.\w+)?\z/)
      end
    end
  end
end
