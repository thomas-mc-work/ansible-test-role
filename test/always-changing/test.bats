#!/usr/bin/env bats

@test "simple check with success" {
  run ./ansible-test-role.sh "$BATS_TEST_DIRNAME/role"
  [ "$status" -eq 0 ]
}

@test "idempotence check with error" {
  run ./ansible-test-role.sh -i "$BATS_TEST_DIRNAME/role"
  [ "$status" -eq 20 ]
}