module Imap::Backup
  describe CLI::Setup do
    subject { described_class.new({}) }

    let(:setup) { instance_double(Setup, run: nil) }
    let(:config) { instance_double(Configuration) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Setup).to receive(:new) { setup }
    end

    it_behaves_like("an action that doesn't require an existing configuration",
      action: ->(subject) { subject.run }
    )

    it "reruns the setup process" do
      subject.run

      expect(setup).to have_received(:run)
    end
  end
end
