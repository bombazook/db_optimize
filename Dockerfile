FROM ruby:latest
RUN apt-get update -qq && apt-get install -y apt-utils build-essential libpq-dev lsb-release curl ca-certificates gnupg curl unzip locate
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN sh -c 'curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -'
RUN apt-get update -qq && apt-get install -y postgresql-client-13
RUN bundle config --global frozen 1
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle check || bundle install
COPY . .
