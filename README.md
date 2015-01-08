You have two options to install logstash + elasticsearch.
Either via Puppet (next version might include vagrant) or via Docker.

The project contains also the configuration files used by logstash.
For info about logstash and elasticsearch take a look at:
- http://logstash.net/docs/1.4.2/
- http://www.elasticsearch.org/guide/

For scaling, you should use a MessageQueue Docker or use the LumberJack system.
This procject is still experimental.

#Puppet

The idea of this project is to contain all the puppet modules and recipes for Logstash and Elastic search.

Also the filters used by logstash and the predefined searchs of Elastic search

To start, execute ./install.sh

To install the necessary puppet modules execute:
`# ./install_modules.sh`
To know the current modules to be installed execute 
`$ git grep puppet_modules install_modules.sh`
And dont forget you can always search for the modules details in https://forge.puppetlabs.com/
`$ puppet apply manifest.pp`

For development instructions, read [DEVELOPMENT.md](DEVELOPMENT.md)

#Docker

Docker usage:
```
docker pull walm/elasticsearch
docker pull pblittle/docker-logstash
docker run -d -p 9200:9200 --name elasticsearch walm/elasticsearch
docker run -d --link elasticsearch:es -p 9998:9998 -p 9999:9999/udp --name logstash -v `pwd`puppet_files/logstash/files/logstash_file.conf:/opt/logstash.conf -v /opt/logs/trans:/var/log/trans pblittle/docker-logstash
docker logs -f logstash # This should show the progress of logstash
```
