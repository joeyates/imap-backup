ARG RUBY_VERSION=3.2
FROM ruby:$RUBY_VERSION-alpine as builder

# install dependencies
RUN apk add libffi-dev alpine-sdk
RUN gem install bundler --version=2.3.22
WORKDIR /app
COPY . .
RUN bundle install
RUN bundle binstubs --all --path /app/bin/stubs

FROM ruby:$RUBY_VERSION-alpine as final
RUN apk add bash --no-cache
ENV HOME=/app \
    PATH=/app/bin/stubs:$PATH
WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app/bin/stubs /app/bin/stubs
COPY . .