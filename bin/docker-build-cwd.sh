#!/bin/bash

IMAGE_NAME="$(basename "$(pwd)")"

echo "Image name: [${IMAGE_NAME}]"

docker build --tag "${IMAGE_NAME}" "$@" .
