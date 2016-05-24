require 'common/default'

describe 'Baragon agent' do
  it_behaves_like 'default installation'

  describe port 8882 do
    it { is_expected.to be_listening }
  end

  describe 'dynamic proxies and upstreams created correctly' do
    describe file '/tmp/default/proxy/tk-test-service.conf' do
      it { is_expected.to be_file }

      describe '#content' do
        subject { super().content }
        it { is_expected.to match(%r(^location  /testbasepath1 {$)) }
        it { is_expected.to match(%r{^  proxy_pass http://baragon_default_tk-test-service;}) }
      end
    end

    describe file '/tmp/default/upstreams/tk-test-service.conf' do
      it { is_expected.to be_file }

      describe '#content' do
        subject { super().content }
        it { is_expected.to match(/^upstream baragon_default_tk-test-service {$/) }
        it { is_expected.to match(/^  server localhost:8123/) }
      end
    end
  end
end
