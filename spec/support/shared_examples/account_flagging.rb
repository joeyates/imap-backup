shared_examples "it flags the account as modified" do
  it "flags that the account has changed" do
    expect(account[:modified]).to be_truthy
  end
end

shared_examples "it doesn't flag the account as modified" do
  it "does not flag that the account has changed" do
    expect(account[:modified]).to be_falsey
  end
end

shared_examples "it flags the account to be deleted" do
  it "flags that the account is to be deleted" do
    expect(account[:delete]).to be_truthy
  end
end

shared_examples "it doesn't flag the account to be deleted" do
  it "does not flags that the account is to be deleted" do
    expect(account[:delete]).to be_falsey
  end
end
