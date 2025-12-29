#!/bin/bash
if [[ ! -f ./_nuke/aws-nuke ]]; then
  wget $(curl https://api.github.com/repos/ekristen/aws-nuke/releases/latest | jq '.assets[]|select(.name|endswith("linux-amd64.tar.gz")).browser_download_url' -r) -O- | tar zxvf - -C ./_nuke
fi

_nuke/aws-nuke nuke -q --force --no-alias-check --no-dry-run -c _nuke/config.yaml $*
