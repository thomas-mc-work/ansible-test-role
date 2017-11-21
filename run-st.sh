#!/usr/bin/env sh
# Run system tests
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value


cd test/playbook

for role_path in roles/*; do
    filename=$(basename "$role_path")
    ../../ansible-test-role.sh "$filename"
done
