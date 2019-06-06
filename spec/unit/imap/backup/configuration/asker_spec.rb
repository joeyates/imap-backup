# rubocop:disable Metrics/ModuleLength

module Imap::Backup
  describe Configuration::Asker do
    subject { described_class.new(highline) }

    let(:highline) { double }
    let(:query) do
      instance_double(
        HighLine::Question,
        "default=": nil,
        "readline=": nil,
        "validate=": nil,
        "responses": {},
        "echo=": nil
      )
    end
    let(:answer) { "foo" }

    before do
      allow(Configuration::Setup).to receive(:highline) { highline }
      allow(highline).to receive(:ask) do |&b|
        b.call query
        answer
      end
    end

    [
      [:email, [], "email address"],
      [:password, [], "password"],
      [:backup_path, %w(x y), "backup directory"]
    ].each do |method, params, prompt|
      context ".#{method}" do
        it "asks for input" do
          described_class.send(method, *params)

          expect(highline).to have_received(:ask).with("#{prompt}: ")
        end

        it "returns the answer" do
          expect(described_class.send(method, *params)).to eq(answer)
        end
      end
    end

    describe "#initialize" do
      it "requires 1 parameter" do
        expect do
          described_class.new
        end.to raise_error(ArgumentError, /wrong number/)
      end

      it "expects a higline" do
        expect(subject.highline).to eq(highline)
      end
    end

    describe "#email" do
      let(:email) { "email@example.com" }
      let(:answer) { email }
      let(:result) { subject.email }

      before { result }

      it "asks for an email" do
        expect(highline).to have_received(:ask).with(/email/)
      end

      it "returns the address" do
        expect(result).to eq(email)
      end
    end

    describe "#password" do
      let(:password1) { "password" }
      let(:password2) { "password" }
      let(:answers) { [true, false] }
      let(:result) { subject.password }

      before do
        i = 0
        allow(highline).to receive(:ask).with("password: ") { password1 }
        allow(highline).to receive(:ask).with("repeat password: ") { password2 }
        allow(highline).to receive(:agree) do
          answer = answers[i]
          i += 1
          answer
        end
        result
      end

      it "asks for a password" do
        expect(highline).to have_received(:ask).with("password: ")
      end

      it "asks for confirmation" do
        expect(highline).to have_received(:ask).with("repeat password: ")
      end

      it "returns the password" do
        expect(result).to eq(password1)
      end

      context "with different answers" do
        let(:password2) { "secret" }

        it "asks to continue" do
          expect(highline).to have_received(:agree).
            at_least(:once).with(/Continue\?/)
        end
      end
    end

    describe "#backup_path" do
      let(:path) { "/path" }
      let(:answer) { path }
      let(:result) { subject.backup_path("", //) }

      before do
        allow(highline).to receive(:ask) do |&b|
          b.call query
          path
        end
        result
      end

      it "asks for a directory" do
        expect(highline).to have_received(:ask).with(/directory/)
      end

      it "returns the path" do
        expect(result).to eq(path)
      end
    end
  end
end

# rubocop:enable Metrics/ModuleLength
