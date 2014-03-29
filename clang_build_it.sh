#!/usr/bin/env bash

export CC=/usr/local/llvm34/bin/clang
export CXX=/usr/local/llvm34/bin/clang++
export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments

./configure --prefix=/usr/local/llvm_ruby186 \
  --with-openssl-dir=/usr/local/openssl98y > c.log 2>&1

make -j4 > m.log 2>&1
make install > i.log 2>&1
