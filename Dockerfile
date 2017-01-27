FROM debian:jessie
ENV \
    EXPOSED_ROOT_DIR="/seafile" \
    SEAFILE_ROOT_DIR="/opt/seafile" \
    SEAFILE_VERSION=6.0.7 \
    SEAFILE_URL_PATTERN=https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_VERSION_x86-64.tar.gz

RUN \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y update && \
    apt-get install --no-install-recommends -y \
        wget \
        python2.7 \
        python-setuptools \
        python-imaging \
        python-ldap \
        python-mysqldb \
        python-urllib3 \
        python-memcache \
        supervisor

RUN \
    DEBIAN_FRONTEND=noninteractive \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /var/log/*

RUN \
    useradd -r -s /bin/false seafile  \
    && mkdir $SEAFILE_ROOT_DIR $EXPOSED_ROOT_DIR \
    && chown seafile:seafile -R $SEAFILE_ROOT_DIR $EXPOSED_ROOT_DIR

RUN \
    cd /usr/local/bin/ \
    && wget --no-check-certificate -qO- $(wget --no-check-certificate -nv -qO- https://api.github.com/repos/jwilder/dockerize/releases/latest \
                | grep -E 'browser_.*dockerize-linux-amd64' | cut -d\" -f4) | tar xzv \
    && chown :seafile dockerize \
    && chmod g+x dockerize

COPY ["script", "/usr/local/bin/"]
COPY ["supervisor", "/etc/supervisor/"]

RUN chown :seafile -R /usr/local/bin/
RUN chmod 770 -R /usr/local/bin/

USER seafile

RUN \
    cd $SEAFILE_ROOT_DIR \
    && wget --no-check-certificate -qO - $(echo $SEAFILE_URL_PATTERN | sed "s/VERSION/$SEAFILE_VERSION/") | tar xz

WORKDIR $SEAFILE_ROOT_DIR

EXPOSE 8000 8082

CMD ["start.sh"]
