#!/usr/bin/env bash

set -ex

BASE='https://raw.githubusercontent.com/cyrus-and/trace/master'
TEMP=$(mktemp -d)

cd "$TEMP"
wget -q "$BASE/trace.sh"
wget -q "$BASE/trace.default.sh"

sudo mkdir /opt/trace/
sudo mv trace.* /opt/trace/
sudo chmod +x /opt/trace/trace.sh
sudo ln -s /opt/trace/trace.sh /usr/local/bin/trace

rm -r "$TEMP"
echo 'Done.'
