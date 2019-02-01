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

ENV FFSYNC_VERSION 1.8.0
ENV FFSYNC_SHA256 728206bcffec7a305e97e7cd4d465b3fa56f39f8e1fd55d98e49a866016d61e0
ENV FFSYNC_URL https://github.com/mozilla-services/syncserver/archive
ENV FFSYNC_FILENAME $FFSYNC_VERSION.tar.gz

RUN apk --update --no-cache add --virtual build.deps \
    python2-dev \
    build-base \
    libffi-dev \
    libressl-dev \
    postgresql-dev \
  && wget $FFSYNC_URL/$FFSYNC_FILENAME \
  && echo "$FFSYNC_SHA256  ./$FFSYNC_FILENAME" | sha256sum -c - \
  && tar -xzf $FFSYNC_FILENAME \
  && cd syncserver-$FFSYNC_VERSION \
  && make build \
  && /opt/syncserver-$FFSYNC_VERSION/local/bin/pip install --upgrade psycopg2 \
  && /opt/syncserver-$FFSYNC_VERSION/local/bin/pip install --upgrade mysql-connector-python \
  && make test \
  && apk del build.deps \
  && rm -r /opt/$FFSYNC_FILENAME

RUN ln -s /opt/syncserver-$FFSYNC_VERSION /opt/syncserver \
  && mv /opt/syncserver/syncserver.ini /data/ \
  && mv /opt/syncserver/syncserver.db /data/ \
  && ln -s /data/syncserver.db /opt/syncserver/syncserver.db \
  && ln -s /data/syncserver.ini /opt/syncserver/syncserver.ini \
  && chown -R app:app /data

VOLUME /data

EXPOSE 5000

USER app

CMD ["/opt/syncserver/local/bin/gunicorn", "--paste", "/data/syncserver.ini", "--user", "app", "--group", "app", "--bind", "0.0.0.0:5000", "syncserver.wsgi_app"]
