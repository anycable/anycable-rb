#!/usr/bin/env bash

# grpc-tools doesn't work on MacOS ARM, so we run it via Docker.
# see https://github.com/grpc/grpc/issues/25755

compose='
services:
  grpc_tools_ruby_protoc:
    build:
      context: .
      dockerfile_inline: |
        FROM ruby:3.3.4

        WORKDIR /app

        RUN dpkg --add-architecture i386
        RUN apt update
        RUN apt install -y libc6:i386
        RUN gem install grpc-tools
    tty: true
    stdin_open: true
    entrypoint: grpc_tools_ruby_protoc
    volumes:
      - .:/app:cached
'

echo "$compose" | docker compose -f - run --rm -T grpc_tools_ruby_protoc $@
