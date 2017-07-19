require 'spec_helper'
require 'net/http'

shared_examples_for 'default installation' do
  it 'is running and enabled' do
    expect(service('baragon-agent-default')).to be_enabled
    # Note that the test service is expected to be "running" (strictly speaking)
    # but it won't actually be working (e.g. listening on port 8882) because it
    # will not start up completely when it is unable to reach Zookeeper.
    expect(service('baragon-agent-default')).to be_running
  end

  describe file '/etc/baragon/agent-default.yml' do
    it { is_expected.to be_file }

    describe '#content' do
      subject { super().content }
      it { is_expected.to include 'upstream baragon_default_{{{service.serviceId}}}' }
      it { is_expected.to match 'sessionTimeoutMillis: 50000' }
      it { is_expected.to_not match '!ruby/hash:Chef::Node::Immutable' }
    end
  end

  describe 'custom response headers' do
    let(:test_response) { Net::HTTP.get_response(URI 'http://localhost:8443/testbasepath1/') }

    expected_headers = {
      'strict-transport-security' => 'max-age=31536000; includeSubDomains;',
      'cache-control' => 'value should not be replaced',
      'pragma' => 'no-cache'
    }

    expected_headers.each do |header, value|
      describe "header: #{header}" do
        it 'is set' do
          expect(test_response.to_hash).to include header
        end

        it 'set to correct value' do
          expect(test_response[header]).to eq value
        end
      end
    end
  end
end
