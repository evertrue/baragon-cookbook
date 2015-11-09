require 'spec_helper'

describe 'Baragon agent' do
  it 'is listening on the specified port' do
    expect(port 8882).to be_listening
  end

  it 'is running and enabled' do
    expect(service('baragon-agent-default')).to be_enabled
    expect(service('baragon-agent-default')).to be_running
  end
end
