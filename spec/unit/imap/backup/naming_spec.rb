require "imap/backup/naming"

module Imap::Backup
  describe Naming do
    describe ".to_local_path" do
      it "returns a String" do
        expect(described_class.to_local_path("ciao")).to be_a(String)
      end

      context "when there are unacceptable characters" do
        it "replaces them" do
          expect(described_class.to_local_path("c:a%")).to eq("c%3a;a%25;")
        end
      end

      context "when there are no unacceptable characters" do
        it "returns the text unchanged" do
          expect(described_class.to_local_path("ciao")).to eq("ciao")
        end
      end

      [
        [":", "%3a;"],
        ["%", "%25;"],
        [";", "%3b;"],
        ["/", "/"],
        ["\\", "\\"],
        ["≈", "≈"]
      ].each do |char, expected|
        if char == expected
          it "does not convert '#{char}'" do
            expect(described_class.to_local_path(char)).to eq(char)
          end
        else
          it "converts '#{char}' to '#{expected}'" do
            expect(described_class.to_local_path(char)).to eq(expected)
          end
        end
      end
    end

    describe ".from_local_path" do
      it "returns a string" do
        expect(described_class.from_local_path("ciao")).to be_a(String)
      end

      context "when there are encoded characters" do
        it "reconverts them to the original" do
          expect(described_class.from_local_path("c%3a;a%25;")).to eq("c:a%")
        end
      end

      context "when there are no encoded characters" do
        it "returns the text unchanged" do
          expect(described_class.from_local_path("ciao")).to eq("ciao")
        end
      end
    end
  end
end
