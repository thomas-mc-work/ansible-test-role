#!/usr/bin/env bats

@test "idempotence check with success" {
  run ./ansible-test-role.sh -i "$BATS_TEST_DIRNAME/role"
  [ "$status" -eq 0 ]
}