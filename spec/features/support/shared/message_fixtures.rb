RSpec.shared_context "message-fixtures" do
  let(:uid_one) { 123 }
  let(:uid_two) { 345 }
  let(:uid_three) { 567 }
  let(:uid_iso8859) { 890 }
  let(:message_one) do
    {uid: uid_one, from: "address@example.org", subject: "Test 1", body: "body 1\nHi"}
  end
  let(:message_two) do
    {uid: uid_two, from: "address@example.org", subject: "Test 2", body: "body 2"}
  end
  let(:message_three) do
    {uid: uid_three, from: "address@example.org", subject: "Test 3", body: "body 3"}
  end
  let(:msg_iso8859) do
    {
      uid: uid_iso8859,
      from: "address@example.org",
      subject: "iso8859 Body",
      body: "Ma, perchè?".encode(Encoding::ISO_8859_1).force_encoding("binary")
    }
  end
end
