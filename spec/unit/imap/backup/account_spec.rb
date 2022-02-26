module Imap::Backup
  describe Account do
    subject { described_class.new(options) }

    let(:options) { {username: "user", password: "pwd"} }

    describe "#changes" do
      it "lists changes" do
        subject.username = "new"

        expect(subject.changes).to eq(username: {from: "user", to: "new"})
      end

      context "when more than one change is made" do
        it "retains the last one" do
          subject.username = "first"
          subject.username = "second"

          expect(subject.changes).to eq(username: {from: "user", to: "second"})
        end
      end

      context "when a value is reset to its original value" do
        it "removes the change" do
          subject.username = "changed"
          subject.username = "user"

          expect(subject.changes).to eq({})
        end
      end
    end

    describe "#connection" do
      it "returns a Connection for the Account" do
        result = subject.connection

        expect(result).to be_a(Account::Connection)
        expect(result.account).to be subject
      end
    end

    describe "#valid?" do
      context "with username and password" do
        it "is true" do
          expect(subject.valid?).to be true
        end
      end

      context "without a username" do
        let(:options) { {password: "pwd"} }

        it "is false" do
          expect(subject.valid?).to be false
        end
      end

      context "without a password" do
        let(:options) { {username: "user"} }

        it "is false" do
          expect(subject.valid?).to be false
        end
      end
    end

    describe "#modified?" do
      context "with changes" do
        it "is true" do
          subject.username = "new"

          expect(subject.modified?).to be true
        end
      end

      context "without changes" do
        it "is false" do
          expect(subject.modified?).to be false
        end
      end
    end

    describe "#clear_changes" do
      it "clears changes" do
        subject.username = "new"
        subject.clear_changes

        expect(subject.changes).to eq({})
      end
    end

    describe "#mark_for_deletion" do
      it "sets marked_for_deletion" do
        subject.mark_for_deletion

        expect(subject.marked_for_deletion?).to be true
      end
    end

    describe "#marked_for_deletion?" do
      it "defaults to false" do
        expect(subject.marked_for_deletion?).to be false
      end
    end

    describe "#to_h" do
      it "returns a Hash representation" do
        expect(subject.to_h).to eq({username: "user", password: "pwd"})
      end

      context "when local_path is set" do
        let(:options) { {username: "user", password: "pwd", local_path: "local_path"} }

        it "includes local_path" do
          expect(subject.to_h).to include({local_path: "local_path"})
        end
      end

      context "when folders is set" do
        let(:options) { {username: "user", password: "pwd", folders: ["folder"]} }

        it "includes folders" do
          expect(subject.to_h).to include({folders: ["folder"]})
        end
      end

      context "when server is set" do
        let(:options) { {username: "user", password: "pwd", server: "server"} }

        it "includes server" do
          expect(subject.to_h).to include({server: "server"})
        end
      end

      context "when connection_options is set" do
        let(:options) { {username: "user", password: "pwd", connection_options: "foo"} }

        it "includes connection_options" do
          expect(subject.to_h).to include({connection_options: "foo"})
        end
      end
    end

    [
      [:username, "username", "username"],
      [:password, "password", "password"],
      [:local_path, "local_path", "local_path"],
      [:server, "server", "server"],
      [:folders, ["folder"], ["folder"]],
      [:connection_options, %q({"some": "option"}), {"some" => "option"}]
    ].each do |attribute, value, expected|
      describe "##{attribute}=" do
        let(:options) { {} }

        before { subject.send(:"#{attribute}=", value) }

        it "sets the #{attribute}" do
          expect(subject.send(attribute)).to eq(expected)
        end

        it "adds a change" do
          expect(subject.changes).to eq(attribute => {from: nil, to: expected})
        end

        if attribute == :folders
          context "when the supplied value is not an Array" do
            it "fails" do
              expect do
                subject.folders = "aaa"
              end.to raise_error(RuntimeError, /must be an Array/)
            end
          end
        end

        if attribute == :connection_options
          context "when the supplied value is not valid JSON" do
            it "fails" do
              expect do
                subject.connection_options = "NOT JSON"
              end.to raise_error(JSON::ParserError)
            end
          end
        end
      end
    end
  end
end
