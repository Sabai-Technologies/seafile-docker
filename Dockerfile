FROM python:3.9-slim-buster

ENV \
    LC_ALL=C \
    LANG=C \
    DEBIAN_FRONTEND=noninteractive \
    EXPOSED_ROOT_DIR=/seafile \
    SEAFILE_ROOT_DIR=/opt/seafile \
    LATEST_SERVER_DIR=/opt/seafile/seafile-server-latest \
    SEAFILE_VERSION=8.0.3 \
    SEAFILE_URL_PATTERN=https://download.seadrive.org/seafile-server_VERSION_x86-64.tar.gz

RUN \
    apt-get -y update \
    && apt-get install --no-install-recommends -y \
        crudini \
        procps \
        wget \
        build-essential \
        sqlite3 \
        default-libmysqlclient-dev \
        libmemcached-dev \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /var/log/*

RUN python3 -m pip install --upgrade pip && rm -r /root/.cache/pip

RUN \
    pip3 install \
           Pillow \
           pylibmc \
           captcha \
           jinja2 \
           sqlalchemy \
           django-pylibmc \
           django-simple-captcha \
           python3-ldap \
           future \
           mysqlclient \
    && rm -r /root/.cache/pip

COPY ["script", "/usr/local/bin/"]

RUN \
    mkdir $SEAFILE_ROOT_DIR $EXPOSED_ROOT_DIR\
    && wget --no-check-certificate -qO - $(echo $SEAFILE_URL_PATTERN | sed "s/VERSION/$SEAFILE_VERSION/") | tar xz -C $SEAFILE_ROOT_DIR \
    && wget --no-check-certificate -qO- $(wget --no-check-certificate -nv -qO- https://api.github.com/repos/jwilder/dockerize/releases/latest \
                | grep -E 'browser_.*dockerize-linux-amd64' | cut -d\" -f4) | tar xzv -C /usr/local/bin/ \
    && chmod 770 -R /usr/local/bin/

EXPOSE 8000 8082

CMD ["start.sh"]
