FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get install -y jq
RUN apt-get update && \
    apt-get install -y mysql-client
COPY . /var/dubanek
CMD ["bash", "/var/dubanek/dubanek.sh"]
