#!/usr/bin/env bash

GRADLE_FILE="./app/build.gradle.kts"

function getProperty {
    # shellcheck disable=SC2046
    # shellcheck disable=SC2005
    # shellcheck disable=SC2002
    echo $(cat $GRADLE_FILE | grep "const val $1" | cut -d'=' -f2)
}

MAJOR=$(getProperty "major")
MINOR=$(getProperty "minor")
PATCH=$(getProperty "patch")

echo "APP_VERSION=$MAJOR.$MINOR.$PATCH" >> "$GITHUB_ENV"