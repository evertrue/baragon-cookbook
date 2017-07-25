require 'common/default'

describe 'Baragon agent' do
  it_behaves_like 'default installation'

  describe port 8882 do
    it { is_expected.to be_listening }
  end

  describe 'dynamic proxies and upstreams created correctly' do
    custom_response_headers = {
      'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains;',
      'Cache-Control' => 'value should not be replaced',
      'Pragma' => 'no-cache',
      'X-Frame-Options' => 'DENY'
    }

    describe file '/tmp/default/proxy/tk-test-service.conf' do
      it { is_expected.to be_file }

      describe '#content' do
        subject { super().content }
        it { is_expected.to match(%r(^location  /testbasepath1 {$)) }
        it { is_expected.to match(%r{^  proxy_pass http://baragon_default_tk-test-service;}) }

        custom_response_headers.keys.each do |header|
          it { is_expected.to match(%r{^  add_header #{header} \$#{header.downcase.gsub('-', '_')}_custom_header always;})}
        end
      end
    end

    describe 'HTTP response' do
      custom_response_headers.each do |header, value|
        it "return header #{header} with value \"#{value}\"" do
          expect(
            Net::HTTP.new('localhost', 8443).get(
              '/testbasepath1/', 'Host' => 'test.local'
            )[header.downcase]
          ).to eq value
        end
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
