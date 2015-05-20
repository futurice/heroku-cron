#!/bin/sh

set -exu

TAG=futurice/cedar-stackage:14-2.9

docker build -t $TAG .
docker run -v `pwd`:/build $TAG
