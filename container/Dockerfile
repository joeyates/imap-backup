ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-buster

# Install dependencies
RUN \
  apt update && \
  apt install --yes libffi-dev


WORKDIR /app

RUN gem install bundler --version=2.1.4

ENTRYPOINT ["bash"]
