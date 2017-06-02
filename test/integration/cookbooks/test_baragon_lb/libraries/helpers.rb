module Baragon
  module Helpers
    def create_test_zk_request
      require 'net/http'

      return if test_request_exist?

      # Wait for the agent to come online and check in
      sleep 0.25 until JSON.parse(
        Net::HTTP.get(URI('http://localhost:8088/baragon/v2/load-balancer/default/agents'))
      ).any?

      lb_request = {
        'loadBalancerRequestId' => "lbreq-#{Time.now.to_i}",
        'loadBalancerService' => {
          'serviceId' => 'tk-test-service',
          'owners' => ['eric.herot@evertrue.com'],
          'serviceBasePath' => '/testbasepath1',
          'loadBalancerGroups' => ['default'],
          'options' => {}
        },
        'addUpstreams' => [{
          'upstream' => 'localhost:8123',
          'requestId' => "upstreamreq-#{Time.now.to_i}",
          'rackId' => 'us-east-1b',
          'group' => 'default'
        }],
        'removeUpstreams' => []
      }

      puts "\nWriting request: upstreamreq-#{Time.now.to_i}"

      uri = URI 'http://localhost:8088/baragon/v2/request'
      req = Net::HTTP::Post.new uri
      req.body = lb_request.to_json
      req.content_type = 'application/json'

      Net::HTTP.start(uri.hostname, uri.port) { |http| http.request req }

      sleep 0.25 while JSON.parse(Net::HTTP.get(URI('http://localhost:8088/baragon/v2/request'))).any?
    end

    def test_request_exist?
      tries = 0
      begin
        Net::HTTP.get_response(URI('http://localhost:8088/baragon/v2/state/tk-test-service'))
                 .code.to_i == 200
      rescue Errno::ECONNREFUSED => e
        puts "Baragon connection refused. Retrying (#{tries})."
        # The Baragon service doesn't necessarily start up instantly at bootstrap
        tries += 1
        sleep 1
        retry if tries < 60
        raise e
      end
    end
  end
end
