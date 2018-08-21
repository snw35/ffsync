FROM alpine:3.8

RUN apk --update --no-cache add \
    python2 \
    py2-virtualenv \
    libstdc++ \
    libffi \
    libssl1.0 \
    py2-pip \
    && pip install --upgrade pip \
    && mkdir /opt \
    && mkdir /data \
    && addgroup -g 1001 app \
    && adduser -u 1001 -S -D -G app -s /usr/sbin/nologin app

WORKDIR /opt

ENV VERSION 1.8.0
ENV DOWNLOAD_SHA256 728206bcffec7a305e97e7cd4d465b3fa56f39f8e1fd55d98e49a866016d61e0
ENV DOWNLOAD_URL https://github.com/mozilla-services/syncserver/archive/$VERSION.tar.gz

RUN apk --update --no-cache add --virtual build.deps \
    python2-dev \
    build-base \
    libffi-dev \
    libressl-dev \
    postgresql-dev \
    && wget $DOWNLOAD_URL \
    && echo "$DOWNLOAD_SHA256  ./$VERSION.tar.gz" | sha256sum -c - \
    && tar -xzf $VERSION.tar.gz \
    && cd syncserver-$VERSION \
    && make build \
    && /opt/syncserver-$VERSION/local/bin/pip install --upgrade psycopg2 \
    && /opt/syncserver-$VERSION/local/bin/pip install --upgrade mysql-connector-python \
    && make test \
    && apk del build.deps \
    && rm -r /opt/$VERSION.tar.gz

RUN ln -s /opt/syncserver-$VERSION /opt/syncserver \
    && mv /opt/syncserver/syncserver.ini /data/ \
    && mv /opt/syncserver/syncserver.db /data/ \
    && ln -s /data/syncserver.db /opt/syncserver/syncserver.db \
    && ln -s /data/syncserver.ini /opt/syncserver/syncserver.ini \
    && chown -R app:app /data

VOLUME /data

EXPOSE 5000

USER app

CMD ["/opt/syncserver/local/bin/gunicorn", "--paste", "/data/syncserver.ini", "--user", "app", "--group", "app", "--bind", "0.0.0.0:5000", "syncserver.wsgi_app"]
