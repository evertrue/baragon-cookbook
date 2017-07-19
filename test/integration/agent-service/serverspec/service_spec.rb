require 'spec_helper'

describe 'BaragonService' do
  it 'is listening on the specified port' do
    expect(port 8088).to be_listening.with('tcp')
  end

  it 'is running and enabled' do
    expect(service('baragon-server')).to be_enabled
    expect(service('baragon-server')).to be_running
  end
end
