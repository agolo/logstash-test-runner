FROM docker.elastic.co/logstash/logstash:5.5.1
COPY ./config/logstash.yml /usr/share/logstash/config/logstash.yml
COPY ./pipeline /usr/share/logstash/pipeline
COPY ./input.log /input.log