require "imap/backup/mirror/map"

module Imap::Backup
  RSpec.describe Mirror::Map do
    subject { described_class.new(pathname: pathname, destination: destination) }

    let(:pathname) { "foo/bar" }
    let(:destination) { "my_account" }
    let(:exists) { false }
    let(:existing) { nil }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(pathname) { exists }
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(pathname) { existing }
      allow(File).to receive(:write).and_call_original
      allow(File).to receive(:write).with(pathname, anything)
    end

    describe "#check_uid_validities" do
      let(:exists) { true }
      let(:existing) do
        {
          destination => {
            "source_uid_validity" => 99,
            "destination_uid_validity" => 100,
            "map" => {"3" => 4}
          }
        }.to_json
      end

      it "returns true" do
        expect(subject.check_uid_validities(source: 99, destination: 100)).to be true
      end

      context "when the source uid_validity does not match" do
        it "returns false" do
          expect(subject.check_uid_validities(source: 42, destination: 100)).to be false
        end
      end

      context "when the destination uid_validity does not match" do
        it "returns false" do
          expect(subject.check_uid_validities(source: 99, destination: 42)).to be false
        end
      end
    end

    describe "#reset" do
      before do
        subject.reset(source_uid_validity: 1, destination_uid_validity: 2)
        subject.save
      end

      it "sets the current source_uid_validity" do
        expect(File).to have_received(:write).with(pathname, /"destination_uid_validity":2/)
      end

      it "sets the current destination_uid_validity" do
        expect(File).to have_received(:write).with(pathname, /"source_uid_validity":1/)
      end

      it "resets the current map" do
        expect(File).to have_received(:write).with(pathname, /"map":{}/)
      end

      context "when other destinations have been saved" do
        let(:exists) { true }
        let(:existing) do
          {
            "existing" => {
              "source_uid_validity" => 99,
              "destination_uid_validity" => 100,
              "map" => {}
            }
          }.to_json
        end

        specify "they are not affected" do
          expect(File).to have_received(:write).with(pathname, /"source_uid_validity":99/)
        end
      end
    end

    describe "#source_uid" do
      context "when data has been set" do
        let(:exists) { true }
        let(:existing) do
          {
            destination => {
              "source_uid_validity" => 99,
              "destination_uid_validity" => 100,
              "map" => {"3" => 4}
            }
          }.to_json
        end

        it "returns the source UID equivalent to the destination UID provided" do
          expect(subject.source_uid(4)).to eq(3)
        end
      end

      context "when the destination UID is unknown" do
        it "returns nil" do
          subject.reset(source_uid_validity: 1, destination_uid_validity: 2)

          expect(subject.source_uid(3)).to be_nil
        end
      end

      context "when UID validities are not set" do
        it "throws an error" do
          expect do
            subject.source_uid(3)
          end.to raise_error(RuntimeError, /Assign UID validities/)
        end
      end
    end

    describe "#destination_uid" do
      context "when data has been set" do
        let(:exists) { true }
        let(:existing) do
          {
            destination => {
              "source_uid_validity" => 99,
              "destination_uid_validity" => 100,
              "map" => {"3" => 4}
            }
          }.to_json
        end

        it "returns the source UID equivalent to the source UID provided" do
          expect(subject.destination_uid(3)).to eq(4)
        end
      end

      context "when the source UID is unknown" do
        it "returns nil" do
          subject.reset(source_uid_validity: 1, destination_uid_validity: 2)

          expect(subject.destination_uid(3)).to be_nil
        end
      end

      context "when UID validities are not set" do
        it "throws an error" do
          expect do
            subject.destination_uid(3)
          end.to raise_error(RuntimeError, /Assign UID validities/)
        end
      end
    end

    describe "#map_uids" do
      it "adds the mapping" do
        subject.reset(source_uid_validity: 1, destination_uid_validity: 2)
        subject.map_uids(source: 3, destination: 4)
        subject.save

        expect(File).to have_received(:write).with(pathname, /"map":{"3":4}/)
      end

      context "when UID validities are not set" do
        it "throws an error" do
          expect do
            subject.map_uids(source: 3, destination: 4)
          end.to raise_error(RuntimeError, /Assign UID validities/)
        end
      end
    end

    describe "#save" do
      it "saves the map" do
        subject.save

        expect(File).to have_received(:write).with(pathname, anything)
      end
    end
  end
end
