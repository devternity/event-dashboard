FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y -q update 
RUN apt-get -y -q install ruby ruby-dev nodejs g++ bundler sqlite3 libsqlite3-dev

RUN mkdir -p /opt/smashing && \
    cd /opt/smashing && \
    gem install bundler && \
    gem install smashing && \
    gem install rspec

VOLUME /app
VOLUME /var/lib/sqlite

WORKDIR /app

EXPOSE 3030

COPY ./Gemfile /app/Gemfile
COPY ./Gemfile.lock /app/Gemfile.lock

RUN /usr/local/bin/bundle install

RUN ls -la /app

CMD ["bash", "-l", "-c", "/usr/local/bin/smashing start -P /var/run/thin.pid"]
