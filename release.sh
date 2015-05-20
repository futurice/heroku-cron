#!/bin/sh

set -exu

./build.sh

cd dist/build/heroku-cron
shasum -a 256 heroku-cron > heroku-cron.checksum
cat heroku-cron.checksum
gpg --output heroku-cron.checksum.sig --sign heroku-cron.checksum
