The idea of this project is to contain all the puppet modules and recipes for Logstash and Elastic search.

Also the filters used by logstash and the predefined searchs of Elastic search

To start, execute ./install.sh

To install the necessary puppet modules execute:
`# ./install_modules.sh`
To know the current modules to be installed execute 
`$ git grep puppet_modules install_modules.sh`
And don't forget you can always search for the modules details in https://forge.puppetlabs.com/
`$ puppet apply manifest.pp`

For development instructions, read [DEVELOPMENT.md](DEVELOPMENT.md)


---

Docker usage:
```
docker run -d -p 9200:9200 --name elasticsearch walm/elasticsearch
docker run -d --link elasticsearch:es -p 9998:9998 -p 9999:9999/udp --name logstash -v `pwd`/files/logstash/files/logstash_file.conf/logstash.conf:/opt/logstash.conf -v /opt/logs/trans:/var/log/trans pblittle/docker-logstash
docker logs -f logstash # This should show the progress of logstash
```
