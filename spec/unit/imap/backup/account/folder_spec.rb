# rubocop:disable RSpec/PredicateMatcher

describe Imap::Backup::Account::Folder do
  subject { described_class.new(connection, "my_folder") }

  let(:imap) do
    instance_double(
      Net::IMAP,
      append: append_response,
      create: nil,
      examine: nil,
      responses: responses
    )
  end
  let(:connection) do
    instance_double(Imap::Backup::Account::Connection, imap: imap)
  end
  let(:missing_mailbox_data) do
    OpenStruct.new(text: "Unknown Mailbox: my_folder")
  end
  let(:missing_mailbox_response) { OpenStruct.new(data: missing_mailbox_data) }
  let(:missing_mailbox_error) do
    Net::IMAP::NoResponseError.new(missing_mailbox_response)
  end
  let(:responses) { [] }
  let(:append_response) { nil }

  describe "#uids" do
    let(:uids) { [5678, 123] }

    before { allow(imap).to receive(:uid_search).and_return(uids) }

    it "lists available messages" do
      expect(subject.uids).to eq(uids.reverse)
    end

    context "with missing mailboxes" do
      before do
        allow(imap).to receive(:examine).and_raise(missing_mailbox_error)
      end

      it "returns an empty array" do
        expect(subject.uids).to eq([])
      end
    end
  end

  describe "#fetch" do
    let(:message_body) { instance_double(String, force_encoding: nil) }
    let(:attributes) { {"RFC822" => message_body, "other" => "xxx"} }
    let(:fetch_data_item) do
      instance_double(Net::IMAP::FetchData, attr: attributes)
    end

    before { allow(imap).to receive(:uid_fetch) { [fetch_data_item] } }

    it "returns the message" do
      expect(subject.fetch(123)).to eq(attributes)
    end

    context "when the server responds with nothing" do
      before { allow(imap).to receive(:uid_fetch) { nil } }

      it "is nil" do
        expect(subject.fetch(123)).to be_nil
      end
    end

    context "when the mailbox doesn't exist" do
      before do
        allow(imap).to receive(:examine).and_raise(missing_mailbox_error)
      end

      it "is nil" do
        expect(subject.fetch(123)).to be_nil
      end
    end

    it "sets the encoding on the message" do
      subject.fetch(123)

      expect(message_body).to have_received(:force_encoding).with("utf-8")
    end
  end

  describe "#folder" do
    it "is the name" do
      expect(subject.folder).to eq("my_folder")
    end
  end

  describe "#exist?" do
    context "when the folder exists" do
      it "is true" do
        expect(subject.exist?).to be_truthy
      end
    end

    context "when the folder doesn't exist" do
      before do
        allow(imap).to receive(:examine).and_raise(missing_mailbox_error)
      end

      it "is false" do
        expect(subject.exist?).to be_falsey
      end
    end
  end

  describe "#create" do
    context "when the folder exists" do
      before { subject.create }

      it "is does not create the folder" do
        expect(imap).to_not have_received(:create)
      end
    end

    context "when the folder doesn't exist" do
      before do
        allow(imap).to receive(:examine).and_raise(missing_mailbox_error)
        subject.create
      end

      it "is does not create the folder" do
        expect(imap).to have_received(:create)
      end
    end
  end

  describe "#uid_validity" do
    let(:responses) { {"UIDVALIDITY" => ["x", "uid validity"]} }

    it "is returned" do
      expect(subject.uid_validity).to eq("uid validity")
    end

    context "when the folder doesn't exist" do
      before do
        allow(imap).to receive(:examine).and_raise(missing_mailbox_error)
      end

      it "raises an error" do
        expect do
          subject.uid_validity
        end.to raise_error(Imap::Backup::FolderNotFound)
      end
    end
  end

  describe "#append" do
    let(:message) do
      instance_double(
        Email::Mboxrd::Message,
        imap_body: "imap body",
        date: message_date
      )
    end
    let(:message_date) { Time.new(2010, 10, 10, 9, 15, 22, 0) }
    let(:append_response) do
      OpenStruct.new(data: OpenStruct.new(code: OpenStruct.new(data: "1 2")))
    end
    let(:result) { subject.append(message) }

    before do
      result
    end

    it "appends the message" do
      expect(imap).to have_received(:append)
    end

    it "sets the date and time" do
      expect(imap).to have_received(:append).
        with(anything, anything, anything, message_date)
    end

    it "returns the new uid" do
      expect(result).to eq(2)
    end

    it "set the new uid validity" do
      expect(subject.uid_validity).to eq(1)
    end
  end
end

# rubocop:enable RSpec/PredicateMatcher
