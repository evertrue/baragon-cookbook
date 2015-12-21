require 'spec_helper'

describe 'Baragon agent' do
  describe file('/etc/baragon/agent-default.yml') do
    it { is_expected.to be_file }

    describe '#content' do
      subject { super().content }
      it do
        is_expected.to match('zookeeper-1.vagrantup.com:2181,' \
                             'zookeeper-2.vagrantup.com:2181')
      end
      it { is_expected.to_not match '!ruby/hash:Chef::Node::Immutable' }
    end
  end
end
