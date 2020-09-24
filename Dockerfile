FROM python:2.7.18-alpine3.11

RUN apk --update --no-cache add \
    libstdc++ \
    libffi \
    libssl1.1 \
    libpq \
  && pip install --no-cache-dir --upgrade pip \
  && mkdir /data \
  && addgroup -g 1001 app \
  && adduser -u 1001 -S -D -G app -s /usr/sbin/nologin app

ENV LANG C.UTF-8

WORKDIR /opt

ENV FFSYNC_VERSION 1.9.1
ENV FFSYNC_SHA256 dd12e7b4d97052ab5227151886a92ecbc368a987c4ad5fef7a9b759197a86c1f
ENV FFSYNC_URL https://github.com/mozilla-services/syncserver/archive
ENV FFSYNC_FILENAME $FFSYNC_VERSION.tar.gz

RUN apk --update --no-cache add --virtual build.deps \
    build-base \
    g++ \
    libffi-dev \
    mariadb-dev \
    musl-dev \
    ncurses-dev \
    openssl-dev \
    bash \
    postgresql-dev \
  && pip install --no-cache-dir --upgrade \
    psycopg2 \
    mysql-connector-python \
  && wget $FFSYNC_URL/$FFSYNC_FILENAME \
  && echo "$FFSYNC_SHA256  ./$FFSYNC_FILENAME" | sha256sum -c - \
  && tar -xzf $FFSYNC_FILENAME \
  && cd syncserver-$FFSYNC_VERSION \
  && pip install --upgrade --no-cache-dir -r requirements.txt \
  && pip install --upgrade --no-cache-dir -r dev-requirements.txt \
  && python ./setup.py develop \
  && flake8 ./syncserver \
  && nosetests -s syncstorage.tests \
  && sh -c "gunicorn --paste syncserver/tests.ini &" \
  && sleep 2 \
  && python -m syncstorage.tests.functional.test_storage \
    --use-token-server http://localhost:5000/token/1.0/sync/1.5 \
  && apk del build.deps \
  && rm -r /opt/$FFSYNC_FILENAME \
  && rm -rf /root/.cache \
  && ln -s /opt/syncserver-$FFSYNC_VERSION /opt/syncserver \
  && mv /opt/syncserver/syncserver.ini /data/ \
  && ln -s /data/syncserver.ini /opt/syncserver/syncserver.ini \
  && chown -R app:app /data

VOLUME /data

EXPOSE 5000

USER app

CMD ["gunicorn", "--paste", "/data/syncserver.ini", "--user", "app", "--group", "app", "--bind", "0.0.0.0:5000", "syncserver.wsgi_app"]
