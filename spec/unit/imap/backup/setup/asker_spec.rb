module Imap::Backup
  describe Setup::Asker do
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
      allow(Setup).to receive(:highline) { highline }
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
          expect(highline).to receive(:ask).with("#{prompt}: ")

          described_class.send(method, *params)
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

      it "asks for an email" do
        expect(highline).to receive(:ask).with(/email/)

        subject.email
      end

      it "returns the address" do
        expect(subject.email).to eq(email)
      end
    end

    describe "#password" do
      let(:password1) { "password" }
      let(:password2) { "password" }
      let(:answers) { [true, false] }

      before do
        i = 0
        allow(highline).to receive(:ask).with("password: ") { password1 }
        allow(highline).to receive(:ask).with("repeat password: ") { password2 }
        allow(highline).to receive(:agree) do
          answer = answers[i]
          i += 1
          answer
        end
      end

      it "asks for a password" do
        expect(highline).to receive(:ask).with("password: ")

        subject.password
      end

      it "asks for confirmation" do
        expect(highline).to receive(:ask).with("repeat password: ")

        subject.password
      end

      it "returns the password" do
        expect(subject.password).to eq(password1)
      end

      context "with different answers" do
        let(:password2) { "secret" }

        it "asks to continue" do
          expect(highline).to receive(:agree).
            at_least(:once).with(/Continue\?/)

          subject.password
        end
      end
    end

    describe "#backup_path" do
      let(:path) { "/path" }
      let(:answer) { path }

      before do
        allow(highline).to receive(:ask) do |&b|
          b.call query
          path
        end
      end

      it "asks for a directory" do
        expect(highline).to receive(:ask).with(/directory/)

        subject.backup_path("", //)
      end

      it "returns the path" do
        expect(subject.backup_path("", //)).to eq(path)
      end
    end
  end
end
