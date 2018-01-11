FROM docker.io/cassandra:3.0.15
MAINTAINER Shrish Srivastava <shrivas@redhat.com>
ENV REFRESHED_AT 2018-01-11

RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install dnsutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY custom-entrypoint.sh /
RUN chgrp 0 /custom-entrypoint.sh  && chmod g+rwx /custom-entrypoint.sh
ENTRYPOINT ["/custom-entrypoint.sh"]
CMD ["cassandra", "-f"]
