module Imap::Backup
  shared_examples "an action that doesn't require an existing configuration" do |action:|
    before do
      allow(Configuration).to receive(:exist?) { false }
    end

    it "works if there is no configuration file" do
      expect do
        action.call(subject)
      end.to_not raise_error
    end
  end

  shared_examples "an action that requires an existing configuration" do |action:|
    before do
      allow(Configuration).to receive(:exist?) { false }
    end

    it "fails if there is no configuration file" do
      expect do
        action.call(subject)
      end.to raise_error(ConfigurationNotFound)
    end
  end
end
