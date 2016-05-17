require 'common/default'

describe 'Baragon agent' do
  it_behaves_like 'default installation'

  describe port 8882 do
    it { is_expected.to be_listening }
  end
end
