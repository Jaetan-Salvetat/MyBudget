#!/usr/bin/env bash

r=$(cat changelog.md)
r="${r//'%'/'%25'}"
r="${r//$'\n'/'%0A'}"
r="${r//$'\r'/'%0D'}"

echo "RELEASE_BODY=$r" >> "$GITHUB_ENV"