class { 'logstash':
	package_url => 'http://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.3.3-1_centos.noarch.rpm',
	java_install => true,
}

class { 'elasticsearch':
  autoupgrade => true,
  package_url => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.1.noarch.rpm',
  datadir => '/var/lib/elasticsearch-data',
  status => 'enabled',
}

elasticsearch::instance { 'es-01': }

elasticsearch::plugin { 'lmenezes/elasticsearch-kopf':
  module_dir => 'kopf',
  instances  => 'es-01'
}


#logstash::configfile { 'filter_apache':
#	template => 'logstash/filter_apache.file.erb',
#	order => 30
#}
