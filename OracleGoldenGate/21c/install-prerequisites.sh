#!/bin/bash
## Copyright (c) 2021, Oracle and/or its affiliates.
set -e

##
##  i n s t a l l - p r e r e q u i s i t e s . s h
##  Installation of prerequisite software
##

packages=(java-1.8.0-openjdk jq libaio libnsl python39-requests python39-psutil tar unzip)

function success() {
    echo "Packages installed after ${sequence} attempts"
    rm -rf /var/cache/yum /var/log/yum* /tmp/yum*
    useradd ogg
    exit 0
}

##  Attempt the module and package installation up to three times
##  in case there are network issues that cause failures.
for sequence in $(seq 3); do
    dnf -y module install nginx python39 && \
    dnf -y install "${packages[@]}"      && success "${sequence}"
done
exit 1
