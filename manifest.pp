class { 'logstash':
	package_url => 'http://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.3.3-1_centos.noarch.rpm',
}

class { 'elasticsearch':
  autoupgrade => true,
  package_url => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.1.noarch.rpm',
}
