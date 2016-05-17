require 'spec_helper'

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
      it { is_expected.to match 'sessionTimeoutMillis: 50000' }
      it { is_expected.to_not match '!ruby/hash:Chef::Node::Immutable' }
    end
  end
end
