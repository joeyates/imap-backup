ARG RUBY_VERSION=3.2
FROM ruby:$RUBY_VERSION-alpine as builder

WORKDIR /app
COPY . .

# install dependencies
RUN apk add libffi-dev alpine-sdk
RUN gem install bundler --version=2.3.22
RUN bundle install

FROM ruby:$RUBY_VERSION-alpine as final
ENV HOME=/config
WORKDIR /app
COPY . .
COPY --from=builder /usr/local/bundle /usr/local/bundle

ENTRYPOINT ["bundle", "exec", "imap-backup"]