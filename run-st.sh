#!/usr/bin/env sh
# Run system tests
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value


for role_path in test/playbook/roles/*; do
    ./ansible-test-role.sh "$role_path"
done
