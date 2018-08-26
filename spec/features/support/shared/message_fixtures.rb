shared_context "message-fixtures" do
  let(:uid1) { 123 }
  let(:uid2) { 345 }
  let(:uid3) { 567 }
  let(:msg1) { {uid: uid1, subject: "Test 1", body: "body 1\nHi"} }
  let(:msg2) { {uid: uid2, subject: "Test 2", body: "body 2"} }
  let(:msg3) { {uid: uid3, subject: "Test 3", body: "body 3"} }
end
