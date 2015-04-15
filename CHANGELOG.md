# Baragon cookbook CHANGELOG

## v2.0.0 (2015-04-15)

* Convert configuration of Baragon agents to a LWRP
  * Breaking: Agent services are named `baragon-agent-<loadBalancerGroup>`
  * Breaking: Proxy and Upstream conf files live in `<rootPath>/<loadBalancerGroup>/upstream|proxy/`
  * Breaking: Config files are now named `/etc/baragon/agent-<loadBalancerGroup>.yml`
* Remove excessive whitespace in proxy and upstream templates
* Replace the agent recipe with a single declaration of the default agent LWRP

## v1.0.1 (2015-01-21)

* Clean up Berksfile
    - Use proper release of `zookeeper` cookbook instead of GitHub release/tag
* Add `supports` statement to metadata for Supermarket

## v1.0.0 (2015-01-18)

* Initial release of baragon
