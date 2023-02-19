module Imap::Backup
  shared_examples "an action that handles Logger options" do
    before do
      allow(Logger).to receive(:setup_logging).and_call_original
      action.call({verbose: true})
    end

    it "configures the logger" do
      expect(Logger).to have_received(:setup_logging)
    end

    it "does not pass the option to the class" do
      expect(klass).to have_received(:new).with(*expected_args)
    end
  end
end
