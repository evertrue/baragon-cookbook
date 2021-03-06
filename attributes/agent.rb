default['baragon']['agent_log_base'] = '/var/log/baragon'

default['baragon']['agent_yaml'] = {
  'server' => {
    'type' => 'simple',
    'applicationContextPath' => '/baragon-agent/v2',
    'connector' => {
      'type' => 'http',
      'port' => 8882
    }
  },
  'zookeeper' => {
    'sessionTimeoutMillis' => 60_000,
    'connectTimeoutMillis' => 5000,
    'retryBaseSleepTimeMilliseconds' => 1_000,
    'retryMaxTries' => 3
  },
  'loadBalancerConfig' => {
    'name' => 'default',
    'domain' => 'vagrant.baragon.biz',
    'rootPath' => '/tmp'
  }
}

default['baragon']['templates']['proxy_template']['filename'] = 'proxy/%s.conf'
default['baragon']['templates']['proxy_template']['template'] = %q(
# This file is managed by Chef and Baragon, local changes will be lost!
#
# Service ID: {{{service.serviceId}}}
# Service base path: {{{service.serviceBasePath}}}
# Last applied: {{formatTimestamp timestamp}} UTC
# Owners:
{{#if service.owners}}
#   - {{{.}}}
{{else}}
#   No owners!
{{/if}}

{{#if upstreams}}
{{#if service.options.nginxExtraConfigs}}
# BEGIN CUSTOM NGINX CONFIGS
{{#each service.options.nginxExtraConfigs}}{{{.}}}
{{/each}}
# END CUSTOM NGINX CONFIGS
{{/if}}

location {{{service.options.nginxLocationModifier}}} {{{service.serviceBasePath}}} {
  proxy_pass_header Server;
  proxy_set_header Host $http_host;
  proxy_redirect off;
  proxy_set_header X-RealIP $remote_addr;
  proxy_set_header X-Scheme $scheme;
  proxy_set_header X-Request-Start "${msec}";

  <%
    if custom_response_headers
      custom_response_headers.each do |header, value|
  %>
  add_header <%= header %> $<%= header.downcase.gsub('-', '_') %>_custom_header always;
  <%
      end
    end
  %>

  <% if cors_regexp %>
  header_filter_by_lua_block {
    if ngx.var.http_origin then
      local cors_regexp = [[<%= cors_regexp %>]]
      local m, err = ngx.re.match(ngx.var.http_origin, cors_regexp)

      if m then
        ngx.header["Access-Control-Allow-Origin"] = ngx.var.http_origin
        ngx.header["Access-Control-Allow-Credentials"] = "true"
      end
    end

    if ngx.req.get_method() == "OPTIONS" then
      ngx.header["Access-Control-Max-Age"] = "1728000"
      ngx.header["Content-Type"] = "text/plain charset=UTF-8"
      ngx.header["Content-Length"] = 0
    end
  }
  <% end %>
  {{#if service.options.nginxProxyPassOverride}}
  proxy_pass http://{{{service.options.nginxProxyPassOverride}}};
  {{else}}
  proxy_pass http://baragon_<%= group %>_{{{service.serviceId}}};
  {{/if}}
  proxy_connect_timeout {{firstOf service.options.nginxProxyConnectTimeout 55}};
  proxy_read_timeout {{firstOf service.options.nginxProxyReadTimeout 60}};

  {{#if service.options.nginxExtraLocationConfigs}}
  # BEGIN CUSTOM NGINX LOCATION CONFIGS
  {{#each service.options.nginxExtraLocationConfigs}}{{{.}}}
  {{/each}}
  # END CUSTOM NGINX LOCATION CONFIGS
  {{/if}}
}
{{else}}
#
# Service is disabled due to no defined upstreams!
# It's safe to delete this file if not needed.
#
{{/if}}
)

default['baragon']['templates']['upstream_template']['filename'] = 'upstreams/%s.conf'
default['baragon']['templates']['upstream_template']['template'] = "
# This file is managed by Chef, local changes will be lost!
#
# Service ID: {{{service.serviceId}}}
# Service base path: {{{service.serviceBasePath}}}
# Last applied: {{formatTimestamp timestamp}} UTC
# Owners:
{{#if service.owners}}
#   - {{{.}}}
{{else}}
#   No owners!
{{/if}}

{{#if upstreams}}
upstream baragon_<%= group %>_{{{service.serviceId}}} {
  {{#each upstreams}}server {{{upstream}}};  # {{{requestId}}}
  {{/each}}
  {{#if service.options.nginxExtraUpstreamConfigs}}
  # BEGIN CUSTOM NGINX UPSTREAM CONFIGS
  {{#each service.options.nginxExtraUpstreamConfigs}}{{{.}}}
  {{/each}}
  # END CUSTOM NGINX UPSTREAM CONFIGS
  {{/if}}
}
{{else}}
#
# Service is disabled due to no defined upstreams!
# It's safe to delete this file if not needed.
#
{{/if}}
"
