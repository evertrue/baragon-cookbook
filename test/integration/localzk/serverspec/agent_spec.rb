require 'spec_helper'

describe 'Baragon agent' do
  describe port 8882 do
    it { is_expected.to be_listening.with('tcp') }
  end

  it 'has a running and enabled baragon-agent service' do
    expect(service('baragon-agent-default')).to be_enabled
    expect(service('baragon-agent-default')).to be_running
  end
end
