ARG RUBY_VERSION=3.2
FROM ruby:$RUBY_VERSION-alpine as builder

# install dependencies
RUN apk add libffi-dev alpine-sdk
RUN gem install bundler --version=2.3.22
COPY . .
RUN bundle install

FROM ruby:$RUBY_VERSION-alpine as final
ENV HOME=/config \
    PATH=/app/bin:$PATH
WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . .

CMD ["imap-backup", "--config", "/config/config.json"]