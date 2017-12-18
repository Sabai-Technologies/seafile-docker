FROM debian:jessie
ENV \
    EXPOSED_ROOT_DIR="/seafile" \
    SEAFILE_ROOT_DIR="/opt/seafile" \
    SEAFILE_VERSION=6.2.3 \
    SEAFILE_URL_PATTERN=https://download.seadrive.org/seafile-server_VERSION_x86-64.tar.gz

RUN \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y update \
    && apt-get -y install -y ca-certificates \
    && update-ca-certificates \
    && apt-get install --no-install-recommends -y \
        wget \
        python2.7 \
        python-setuptools \
        python-imaging \
        python-ldap \
        python-mysqldb \
        python-urllib3 \
        python-memcache \
        supervisor \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /var/log/* \
    && easy_install pip \
    && pip install requests_oauthlib

COPY ["script", "/usr/local/bin/"]
COPY ["supervisor", "/etc/supervisor/"]

RUN \
    mkdir $SEAFILE_ROOT_DIR $EXPOSED_ROOT_DIR\
    && wget -qO - $(echo $SEAFILE_URL_PATTERN | sed "s/VERSION/$SEAFILE_VERSION/") | tar xz -C $SEAFILE_ROOT_DIR \
    && wget -qO- $(wget -nv -qO- https://api.github.com/repos/jwilder/dockerize/releases/latest \
                | grep -E 'browser_.*dockerize-linux-amd64' | cut -d\" -f4) | tar xzv -C /usr/local/bin/ \
    && chmod 770 -R /usr/local/bin/

EXPOSE 8000 8082

CMD ["start.sh"]