#!/usr/bin/env bash

./configure --prefix=/usr/local/ruby186 \
  --with-openssl-dir=/usr/local/openssl98y > c.log 2>&1
make > m.log 2>&1
make install > i.log 2>&1