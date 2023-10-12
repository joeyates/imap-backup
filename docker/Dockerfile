ARG RUBY_VERSION=3.2
FROM ruby:$RUBY_VERSION-alpine as builder

# install dependencies
RUN apk add libffi-dev alpine-sdk
RUN gem install bundler --version=2.3.22
COPY . .
RUN bundle install

FROM ruby:$RUBY_VERSION-alpine as final
ENV HOME=/app \
    PATH=/app/bin/stubs:$PATH
WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder .bins/stubs /app/bin/stubs
COPY . .