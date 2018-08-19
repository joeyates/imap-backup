shared_context "message-fixtures" do
  let(:uid1) { 123 }
  let(:uid2) { 345 }
  let(:msg1) { {uid: uid1, subject: "Test 1", body: "body 1\nHi"} }
  let(:msg2) { {uid: uid2, subject: "Test 2", body: "body 2"} }
end
