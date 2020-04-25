#!/bin/bash

#set -x
set -e
set -o pipefail

get_version()
{
    git describe --tags --dirty --always --match="$TRAVIS_TAG"
}

is_calver()
{
    local tag="$1"
    echo "$tag" | grep -q -E "^[0-9][0-9]\.[0-9][0-9]?\.[0-9][0-9]*"
}

version="$(get_version)"

if is_calver "$version" && [ "$DOCKER_USERNAME" != "" ] && [ "$DOCKER_PASSWORD" != "" ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker build -t xgaf .
    docker images
    image="rmud/xgaf"
    version_tag="$image:$version"
    latest_tag="$image:latest"
    docker tag xgaf "$version_tag"
    docker tag xgaf "$latest_tag"
    docker push "$version_tag"
    docker push "$latest_tag"
else
    docker build -t xgaf .
fi

