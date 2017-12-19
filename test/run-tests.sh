#!/usr/bin/env sh
# Run system tests
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

export PATH=$PATH:$(pwd)

for test_case in test/*/*.bats; do
    bats "$test_case"
    echo
done
