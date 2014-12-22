class { 'logstashforwarder': 
	package_url => 'http://download.website.com/packages/logstashforwarder.rpm'
}

yumrepo { 'logstash' :
	name => 'logstash-repository-for-1.4.x-packages',
	baseurl => 'http://packages.elasticsearch.org/logstash/1.4/centos',
	gpgcheck => 1,
	gpgkey => 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch',
	enabled => 1,
}

$logstash_init_hash = {
	'START' => 'true'
}

class { 'logstash':
	java_install => true,
	ensure => 'present',
	#ensure => 'absent',
	status => 'running',
	restart_on_change => true,
	#configdir => '/etc/logstash/conf.d',
	init_defaults => $logstash_init_hash,
}

file { 'logstash.conf':
	source => '/etc/puppet/modules/logstash/files/logstash_basic.conf',
	path => '/etc/logstash/conf.d/logstash.conf',
	ensure => present,
	#ensure => absent,
	force => true,
}

yumrepo { 'elasticsearch' :
	name => 'elasticsearch-repository-for-1.1.x-packages',
	baseurl => 'http://packages.elasticsearch.org/elasticsearch/1.1/centos',
	gpgcheck => 1,
	gpgkey => 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch',
	enabled => 1,
}

class { 'elasticsearch':
  version => '1.1.1-1',
  ensure => 'present',
  #ensure => 'absent',
  java_install => true,
  datadir => '/var/lib/elasticsearch-data',
  status => 'running',
  restart_on_change => true,
  config => { 'cluster.name' => 'elasticsearch' }
}

file { 'logstash.conf':
	source => '/etc/puppet/modules/elasticsearch/files/elasticsearch.yml',
	path => '/etc/elasticsearch/elasticsearch.yml',
	ensure => present,
	#ensure => absent,
	force => true,
}

elasticsearch::instance { 'es-01':
	ensure => 'present',
	status => 'running',
	config => { 'node.name' => 'es-01' }
}

elasticsearch::plugin { 'lmenezes/elasticsearch-kopf':
  module_dir => 'kopf',
  instances  => 'es-01'
}
