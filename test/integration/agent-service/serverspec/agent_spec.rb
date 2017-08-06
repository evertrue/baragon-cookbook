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

    describe 'HTTP GET response' do
      custom_response_headers.each do |header, value|
        it "return header #{header} with value \"#{value}\"" do
          expect(
            Net::HTTP.new('localhost', 8443).get(
              '/testbasepath1/',
              'Host' => 'test.local',
              'Origin' => 'https://app.test.local'
            )[header.downcase]
          ).to eq value
        end
      end
    end

    describe 'No origin header is present' do
      it 'return w/o Access-Control-Allow-Origin header' do
        origin = 'https://app.test.local/foobar'
        expect(
          Net::HTTP.new('localhost', 8443).options(
            '/testbasepath1/',
            'Host' => 'test.local'
          )['Access-Control-Allow-Origin']
        ).to eq nil
      end
    end

    describe 'HTTP OPTIONS response' do
      # Test for CORS pre-flight headers
      {
        'Access-Control-Max-Age' => '1728000',
        'Content-Type' => 'text/plain charset=UTF-8',
        'Content-Length' => '0',
        'Access-Control-Allow-Origin' => 'https://app.test.local'
      }.each do |header, value|
        it "return header #{header} with value \"#{value}\"" do
          expect(
            Net::HTTP.new('localhost', 8443).options(
              '/testbasepath1/',
              'Host' => 'test.local',
              'Origin' => 'https://app.test.local'
            )[header.downcase]
          ).to eq value
        end
      end

      describe 'with valid origin' do
        it 'return Access-Control-Allow-Origin header w/o port' do
          origin = 'https://app.test.local/foobar'
          expect(
            Net::HTTP.new('localhost', 8443).options(
              '/testbasepath1/',
              'Host' => 'test.local',
              'Origin' => origin
            )['Access-Control-Allow-Origin']
          ).to eq origin
        end

        it 'return Access-Control-Allow-Origin header w/port' do
          origin = 'https://app.test.local:8080/foobar'
          expect(
            Net::HTTP.new('localhost', 8443).options(
              '/testbasepath1/',
              'Host' => 'test.local',
              'Origin' => origin
            )['Access-Control-Allow-Origin']
          ).to eq origin
        end

        it 'return Access-Control-Allow-Origin header w/o path' do
          origin = 'https://app.test.local/foobar'
          expect(
            Net::HTTP.new('localhost', 8443).options(
              '/testbasepath1/',
              'Host' => 'test.local',
              'Origin' => origin
            )['Access-Control-Allow-Origin']
          ).to eq origin
        end
      end

      describe 'with invalid origin' do
        it "return no Access-Control-Allow-Origin header" do
          origin = 'https://invalid.origin/foobar'
          expect(
            Net::HTTP.new('localhost', 8443).options(
              '/testbasepath1/',
              'Host' => 'test.local',
              'Origin' => origin
            )['Access-Control-Allow-Origin']
          ).to eq nil
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
