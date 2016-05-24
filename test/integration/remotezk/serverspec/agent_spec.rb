require 'common/default'

describe 'Baragon agent' do
  it_behaves_like 'default installation'

  describe file('/etc/baragon/agent-default.yml') do
    describe '#content' do
      subject { super().content }
      it do
        is_expected.to match('zookeeper-1.vagrantup.com:2181,' \
                             'zookeeper-2.vagrantup.com:2181')
      end
    end
  end
end
