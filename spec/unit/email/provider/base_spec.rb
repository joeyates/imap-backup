require "imap/backup/email/provider/base"

module Imap::Backup
  RSpec.describe Email::Provider::Base do
    describe "#folder_ignore_tags" do
      it "returns an empty array" do
        expect(subject.folder_ignore_tags).to eq([])
      end
    end

    describe "#options" do
      it "returns options" do
        expect(subject.options).to be_a(Hash)
      end

      it "forces TLSv1_2" do
        expect(subject.options[:ssl][:min_version]).to eq(OpenSSL::SSL::TLS1_2_VERSION)
      end
    end

    describe "#root" do
      it "is an nil" do
        expect(subject.root).to be_nil
      end
    end

    describe "#sets_seen_flags_on_fetch?" do
      it "is false" do
        expect(subject.sets_seen_flags_on_fetch?).to be false
      end
    end
  end
end
