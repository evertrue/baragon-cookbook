require 'spec_helper'

describe 'BaragonService' do
  describe port 8088 do
    it { is_expected.to be_listening.with('tcp') }
  end

  it 'has a running and enabled baragon-server service' do
    expect(service('baragon-server')).to be_enabled
    expect(service('baragon-server')).to be_running
  end
end

describe 'ZooKeeper' do
  describe port(2181) do
    it { is_expected.to be_listening.with('tcp6') }
  end
end
