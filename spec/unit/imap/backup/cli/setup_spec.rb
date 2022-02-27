module Imap::Backup
  describe CLI::Setup do
    subject { described_class.new }

    let(:setup) { instance_double(Setup, run: nil) }

    before do
      allow(Setup).to receive(:new) { setup }
    end

    it "reruns the setup process" do
      subject.run

      expect(setup).to have_received(:run)
    end
  end
end
